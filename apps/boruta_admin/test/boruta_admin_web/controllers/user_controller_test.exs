defmodule BorutaAdminWeb.UserControllerTest do
  use BorutaAdminWeb.ConnCase

  import BorutaIdentity.AccountsFixtures

  alias BorutaIdentity.Accounts.User

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  test "returns a 401", %{conn: conn} do
    assert conn
           |> get(Routes.admin_user_path(conn, :index))
           |> json_response(401) == %{
             "code" => "UNAUTHORIZED",
             "message" => "The client is unauthorized to access this resource."
           }

    assert conn
           |> patch(Routes.admin_user_path(conn, :update, "id"))
           |> json_response(401) == %{
             "code" => "UNAUTHORIZED",
             "message" => "The client is unauthorized to access this resource."
           }

    assert conn
           |> delete(Routes.admin_user_path(conn, :delete, "id"))
           |> json_response(401) == %{
             "code" => "UNAUTHORIZED",
             "message" => "The client is unauthorized to access this resource."
           }
  end

  describe "with bad scope" do
    @tag authorized: ["bad:scope"]
    test "returns a 403", %{conn: conn} do
      assert conn
             |> get(Routes.admin_user_path(conn, :index))
             |> json_response(403) == %{
               "code" => "FORBIDDEN",
               "message" => "The client is forbidden to access this resource."
             }

      assert conn
             |> patch(Routes.admin_user_path(conn, :update, "id"))
             |> json_response(403) == %{
               "code" => "FORBIDDEN",
               "message" => "The client is forbidden to access this resource."
             }

      assert conn
             |> delete(Routes.admin_user_path(conn, :delete, "id"))
             |> json_response(403) == %{
               "code" => "FORBIDDEN",
               "message" => "The client is forbidden to access this resource."
             }
    end
  end

  describe "index" do
    @tag authorized: ["users:manage:all"]
    test "lists all users", %{conn: conn} do
      conn = get(conn, Routes.admin_user_path(conn, :index))
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "current" do
    @tag :skip
    @tag authorized: ["users:manage:all"]
    test "get current user", %{conn: conn, introspected_token: introspected_token} do
      conn = get(conn, Routes.admin_user_path(conn, :current))

      assert json_response(conn, 200)["data"] == %{
               "id" => introspected_token["sub"],
               "email" => introspected_token["username"]
             }
    end
  end

  describe "update resource_owner" do
    setup %{conn: conn} do
      resource_owner = user_fixture()
      scope = Boruta.Factory.insert(:scope)

      {:ok, conn: conn, resource_owner: resource_owner, existing_scope: scope}
    end

    @tag authorized: ["users:manage:all"]
    test "renders resource_owner when data is valid", %{
      conn: conn,
      resource_owner: %User{id: id} = resource_owner,
      existing_scope: scope
    } do
      conn =
        put(conn, Routes.admin_user_path(conn, :update, resource_owner),
          user: %{
            "authorized_scopes" => [%{"name" => scope.name}]
          }
        )

      assert %{"id" => ^id} = json_response(conn, 200)["data"]
    end
  end

  describe "delete" do
    @tag authorized: ["users:manage:all"]
    test "returns a 404", %{conn: conn} do
      user_id = SecureRandom.uuid()

      conn =
        delete(conn, Routes.admin_user_path(conn, :update, user_id))

      assert response(conn, 404)
    end

    @tag authorized: ["users:manage:all"]
    test "deletes the user", %{conn: conn} do
      %{id: user_id} = user_fixture()

      conn =
        delete(conn, Routes.admin_user_path(conn, :update, user_id))

      assert response(conn, 204)
      refute BorutaIdentity.Repo.get(User, user_id)
    end
  end
end
