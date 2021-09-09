defmodule BorutaAdminWeb.ClientController do
  use BorutaAdminWeb, :controller

  import BorutaAdminWeb.Authorization, only: [
    authorize: 2
  ]

  alias Boruta.Ecto.Admin
  alias Boruta.Ecto.Client

  plug :authorize, ["clients:manage:all"]

  action_fallback BorutaAdminWeb.FallbackController

  def index(conn, _params) do
    clients = Admin.list_clients()
    render(conn, "index.json", clients: clients)
  end

  def create(conn, %{"client" => client_params}) do
    with {:ok, %Client{} = client} <- Admin.create_client(client_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.admin_client_path(conn, :show, client))
      |> render("show.json", client: client)
    end
  end

  def show(conn, %{"id" => id}) do
    client = Admin.get_client!(id)
    render(conn, "show.json", client: client)
  end

  def update(conn, %{"id" => id, "client" => client_params}) do
    client = Admin.get_client!(id)

    with {:ok, %Client{} = client} <- Admin.update_client(client, client_params) do
      render(conn, "show.json", client: client)
    end
  end

  def delete(conn, %{"id" => id}) do
    client = Admin.get_client!(id)

    with {:ok, %Client{}} <- Admin.delete_client(client) do
      send_resp(conn, :no_content, "")
    end
  end
end