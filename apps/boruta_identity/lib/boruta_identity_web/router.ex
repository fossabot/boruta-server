defmodule BorutaIdentityWeb.Router do
  use BorutaIdentityWeb, :router
  use Plug.ErrorHandler

  import BorutaIdentityWeb.Sessions,
    only: [
      fetch_current_user: 2,
      redirect_if_user_is_authenticated: 2,
      require_authenticated_user: 2
    ]

  alias BorutaIdentity.Configuration
  alias BorutaIdentity.Configuration.ErrorTemplate

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_flash)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
    plug(:fetch_current_user)
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  # scope "/", BorutaIdentityWeb do
  #   pipe_through :browser

  #   get "/", PageController, :index
  # end

  ## Authentication routes

  scope "/", BorutaIdentityWeb do
    pipe_through([:browser, :redirect_if_user_is_authenticated])

    get("/users/register", UserRegistrationController, :new)
    post("/users/register", UserRegistrationController, :create)
    get("/users/log_in", UserSessionController, :new)
    post("/users/log_in", UserSessionController, :create)
    get("/users/reset_password", UserResetPasswordController, :new)
    post("/users/reset_password", UserResetPasswordController, :create)
  end

  scope "/", BorutaIdentityWeb do
    pipe_through([:browser, :require_authenticated_user])

    get("/users/choose_session", ChooseSessionController, :index)
    get("/users/consent", UserConsentController, :index)
    post("/users/consent", UserConsentController, :consent)
    get("/users/settings", UserSettingsController, :edit)
    put("/users/settings", UserSettingsController, :update)
  end

  scope "/", BorutaIdentityWeb do
    pipe_through([:browser])

    get("/users/log_out", UserSessionController, :delete)
    get("/users/confirm", UserConfirmationController, :new)
    post("/users/confirm", UserConfirmationController, :create)
    get("/users/confirm/:token", UserConfirmationController, :confirm)
    get("/users/reset_password/:token", UserResetPasswordController, :edit)
    put("/users/reset_password/:token", UserResetPasswordController, :update)
  end

  @impl Plug.ErrorHandler
  def handle_errors(conn, %{reason: reason}) do
    reason = %{
      message: Map.get(reason, :message, inspect(reason))
    }

    %ErrorTemplate{content: template} = Configuration.get_error_template!(conn.status)

    context = %{
      reason: reason,
      boruta_logo_path:
        BorutaIdentityWeb.Router.Helpers.static_path(
          BorutaIdentityWeb.Endpoint,
          "/images/logo-yellow.png"
        )
    }

    content = Mustachex.render(template, context)

    conn
    |> put_resp_content_type("text/html")
    |> send_resp(conn.status, content)
  end
end
