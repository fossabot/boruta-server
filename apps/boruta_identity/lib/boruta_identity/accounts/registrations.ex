defmodule BorutaIdentity.Accounts.RegistrationError do
  @enforce_keys [:message]
  defexception [:message, :changeset, :template]

  @type t :: %__MODULE__{
          message: String.t(),
          changeset: Ecto.Changeset.t() | nil,
          template: BorutaIdentity.IdentityProviders.Template.t()
        }

  def exception(message) when is_binary(message) do
    %__MODULE__{message: message}
  end

  def message(exception) do
    exception.message
  end
end

defmodule BorutaIdentity.Accounts.RegistrationApplication do
  @moduledoc """
  TODO RegistrationApplication documentation
  """

  @callback registration_initialized(
              context :: any(),
              template :: BorutaIdentity.IdentityProviders.Template.t()
            ) :: any()

  @callback user_registered(
              context :: any(),
              user :: BorutaIdentity.Accounts.User.t(),
              session_token :: String.t()
            ) ::
              any()

  @callback registration_failure(
              context :: any(),
              error :: BorutaIdentity.Accounts.RegistrationError.t()
            ) :: any()
end

defmodule BorutaIdentity.Accounts.Registrations do
  @moduledoc false

  import BorutaIdentity.Accounts.Utils, only: [defwithclientrp: 2]

  alias BorutaIdentity.Accounts.RegistrationError
  alias BorutaIdentity.Accounts.Sessions
  alias BorutaIdentity.Accounts.User
  alias BorutaIdentity.IdentityProviders
  alias BorutaIdentity.IdentityProviders.IdentityProvider

  @type registration_params :: map()

  @callback register(
              registration_params :: registration_params(),
              confirmation_url_fun :: (token :: String.t() -> confirmation_url :: String.t()),
              opts :: Keyword.t()
            ) ::
              {:ok, user :: User.t()}
              | {:error, reason :: String.t()}
              | {:error, changeset :: Ecto.Changeset.t()}

  @spec initialize_registration(context :: any(), client_id :: String.t(), module :: atom()) ::
          callback_result :: any()
  defwithclientrp initialize_registration(context, client_id, module) do
    module.registration_initialized(context, new_registration_template(client_rp))
  end

  @spec register(
          context :: any(),
          client_id :: String.t(),
          registration_params :: registration_params(),
          confirmation_url_fun :: (token :: String.t() -> confirmation_url :: String.t()),
          module :: atom()
        ) :: calback_result :: any()
  defwithclientrp register(
                    context,
                    client_id,
                    registration_params,
                    confirmation_url_fun,
                    module
                  ) do
    client_impl = IdentityProvider.implementation(client_rp)

    with {:ok, user} <-
           apply(client_impl, :register, [
             registration_params,
             confirmation_url_fun,
             [confirmable?: client_rp.confirmable]
           ]),
         %User{} = user <- apply(client_impl, :domain_user!, [user]),
         {:ok, user, session_token} <- Sessions.create_user_session(user) do
      # TODO do not log in user if confirmable is set
      module.user_registered(context, user, session_token)
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        module.registration_failure(context, %RegistrationError{
          changeset: changeset,
          message: "Could not create user with given params.",
          template: new_registration_template(client_rp)
        })

      {:error, reason} ->
        module.registration_failure(context, %RegistrationError{
          message: reason,
          template: new_registration_template(client_rp)
        })
    end
  end

  defp new_registration_template(identity_provider) do
    IdentityProviders.get_identity_provider_template!(identity_provider.id, :new_registration)
  end
end
