defmodule BorutaIdentityWeb.Authenticable do
  @moduledoc false

  use BorutaIdentityWeb, :controller

  alias Boruta.Oauth
  alias BorutaIdentity.Accounts

  # Make the remember me cookie valid for 60 days.
  # If you want bump or reduce this value, also change
  # the token expiry itself in UserToken.
  @session_key :user_token
  @max_age 60 * 60 * 24 * 60
  @remember_me_cookie "_boruta_identity_web_user_remember_me"
  @remember_me_options [sign: true, max_age: @max_age, same_site: "Lax"]

  @spec remember_me_cookie() :: String.t()
  def remember_me_cookie, do: @remember_me_cookie

  @doc """
  Logs the user in.

  It renews the session ID and clears the whole session
  to avoid fixation attacks. See the renew_session
  function to customize this behaviour.

  It also sets a `:live_socket_id` key in the session,
  so LiveView sessions are identified and automatically
  disconnected on log out. The line can be safely removed
  if you are not using LiveView.
  """
  @spec log_in(conn :: Plug.Conn.t(), %Accounts.User{}) :: conn :: Plug.Conn.t()
  @spec log_in(conn :: Plug.Conn.t(), %Accounts.User{}, map()) :: conn :: Plug.Conn.t()
  def log_in(conn, user, params \\ %{}) do
    token = Accounts.generate_user_session_token(user)

    conn
    |> put_session(:user_token, token)
    |> put_session(:live_socket_id, "users_sessions:#{Base.url_encode64(token)}")
    |> maybe_write_remember_me_cookie(token, params)
    |> redirect(to: after_sign_in_path(conn))
  end

  @spec store_user_session(conn :: Plug.Conn.t(), session_token :: String.t()) ::
          conn :: Plug.Conn.t()
  def store_user_session(%Plug.Conn{body_params: params} = conn, session_token) do
    conn
    |> put_session(@session_key, session_token)
    |> put_session(:live_socket_id, "users_sessions:#{Base.url_encode64(session_token)}")
    |> maybe_write_remember_me_cookie(session_token, params["user"])
  end

  @spec get_user_session(conn :: Plug.Conn.t()) :: session_token :: String.t()
  def get_user_session(conn) do
    get_session(conn, @session_key)
  end

  @spec remove_user_session(conn :: Plug.Conn.t()) :: conn :: Plug.Conn.t()
  def remove_user_session(conn) do
    conn
    |> delete_resp_cookie(@remember_me_cookie)
    |> delete_session(@session_key)
  end

  defp maybe_write_remember_me_cookie(conn, token, %{"remember_me" => "true"}) do
    put_resp_cookie(conn, @remember_me_cookie, token, @remember_me_options)
  end

  defp maybe_write_remember_me_cookie(conn, _token, _params) do
    conn
  end

  # TODO test it
  @spec after_sign_in_path(conn :: Plug.Conn.t()) :: String.t()
  def after_sign_in_path(conn), do: user_return_to_from_request(conn) || "/"

  # TODO test it
  @spec after_registration_path(conn :: Plug.Conn.t()) :: String.t()
  def after_registration_path(conn), do: user_return_to_from_request(conn) || "/"

  # TODO test it
  @spec after_sign_out_path(conn :: Plug.Conn.t()) :: String.t()
  def after_sign_out_path(%Plug.Conn{query_params: query_params} = conn) do
    Routes.user_session_path(conn, :new, query_params)
  end

  @spec request_param(conn :: Plug.Conn.t()) :: request_param :: String.t()
  def request_param(conn) do
    case Oauth.Request.authorize_request(conn, %Oauth.ResourceOwner{sub: ""}) do
      {:ok, %_{client_id: client_id, scope: scope}} ->
        {:ok, jwt, _payload} =
          Joken.encode_and_sign(
            %{
              "client_id" => client_id,
              "scope" => scope,
              # TODO keep prompt and max_age params
              "user_return_to" => user_return_to(conn)
            },
            BorutaIdentityWeb.Token.application_signer()
          )

        jwt

      _ ->
        ""
    end
  end

  @spec user_return_to(conn :: Plug.Conn.t()) :: return_to_path :: String.t()
  def user_return_to(conn) do
    current_path(conn)
    |> String.replace(~r/prompt=(login|none)/, "")
    |> String.replace(~r/max_age=(\d+)/, "")
  end

  @spec scope_from_request(conn :: Plug.Conn.t()) :: String.t() | nil
  def scope_from_request(%Plug.Conn{query_params: query_params}) do
    with {:ok, claims} <-
           BorutaIdentityWeb.Token.verify(
             query_params["request"] || "",
             BorutaIdentityWeb.Token.application_signer()
           ),
         {:ok, scope} <- Map.fetch(claims, "scope") do
      scope
    else
      _ -> nil
    end
  end

  @spec client_id_from_request(conn :: Plug.Conn.t()) :: String.t() | nil
  def client_id_from_request(%Plug.Conn{query_params: query_params}) do
    with {:ok, claims} <-
           BorutaIdentityWeb.Token.verify(
             query_params["request"] || "",
             BorutaIdentityWeb.Token.application_signer()
           ),
         {:ok, client_id} <- Map.fetch(claims, "client_id") do
      client_id
    else
      _ -> nil
    end
  end

  @spec user_return_to_from_request(conn :: Plug.Conn.t()) :: String.t() | nil
  def user_return_to_from_request(%Plug.Conn{query_params: query_params}) do
    with {:ok, claims} <-
           BorutaIdentityWeb.Token.verify(
             query_params["request"] || "",
             BorutaIdentityWeb.Token.application_signer()
           ),
         {:ok, user_return_to} <- Map.fetch(claims, "user_return_to") do
      user_return_to
    else
      _ -> nil
    end
  end
end
