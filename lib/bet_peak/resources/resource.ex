defmodule BetPeak.Resources.Resource do
  use Ecto.Schema
  import Ecto.Changeset

  schema "resources" do
    field :name, :string

    has_many :permissions, BetPeak.Permissions.Permission

    timestamps(type: :utc_datetime)
  end

  def changeset(resource, attrs, _opts) do
    resource
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> validate_length(:name, min: 2, max: 50)
    |> unique_constraint(:name)
  end
end
