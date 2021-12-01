defmodule BorutaIdentity.RelyingParties.RelyingParty do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  @types [
    "internal"
  ]

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "relying_parties" do
    field :name, :string
    field :type, :string

    timestamps()
  end

  @doc false
  def changeset(relying_party, attrs) do
    relying_party
    |> cast(attrs, [:name, :type])
    |> validate_required([:name, :type])
    |> validate_inclusion(:type, @types)
  end
end