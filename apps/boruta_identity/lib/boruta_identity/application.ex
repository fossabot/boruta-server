defmodule BorutaIdentity.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias Boruta.Gateway.Upstreams

  def start(_type, _args) do
    children = [
      BorutaIdentity.Repo
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: BorutaIdentity.Supervisor)
  end
end