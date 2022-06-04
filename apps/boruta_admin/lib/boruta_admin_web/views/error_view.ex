defmodule BorutaAdminWeb.ErrorView do
  use BorutaAdminWeb, :view

  def render("404.json", _assigns) do
    %{
      code: "NOT_FOUND",
      message: "The requested resource could not be found."
    }
  end

  def render("401.json", _assigns) do
    %{
      code: "UNAUTHORIZED",
      message: "You are unauthorized to access this resource."
    }
  end

  def render("403.json", _assigns) do
    %{
      code: "FORBIDDEN",
      message: "You are forbidden to access this resource."
    }
  end

  def template_not_found(template, _assigns) do
    Phoenix.Controller.status_message_from_template(template)
  end
end
