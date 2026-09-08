defmodule BetPeak.Sports.Sport do
  use Ecto.Schema
  import Ecto.Changeset

  schema "sports" do
    field :name, :string
    field :description, :string
    field :active, :boolean, default: true
    field :slug, :string

    belongs_to :user, BetPeak.Accounts.User
    has_many :teams, BetPeak.Teams.Teams

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(sport, attrs, _opts) do
    sport
    |> cast(attrs, [:name, :description, :active, :user_id])
    |> validate_required([:name, :description, :active, :user_id])
    |> validate_length(:name, min: 2)
    |> validate_length(:description, min: 10)
    |> unique_constraint(:name)
    |> generate_slug()
  end

  defp generate_slug(changeset) do
    if changeset.valid? do
      name = get_change(changeset, :name) || get_field(changeset, :name)

      slug =
        name
        |> String.downcase()
        |> String.replace(~r/\s+/, "-")

      put_change(changeset, :slug, slug)
    else
      changeset
    end
  end
end
