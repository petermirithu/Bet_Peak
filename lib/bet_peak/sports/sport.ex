defmodule BetPeak.Sports.Sport do
  use Ecto.Schema
  import Ecto.Changeset

  schema "sports" do
    field :name, :string
    field :description, :string
    field :active, :boolean, default: true
    field :deleted_at, :utc_datetime

    belongs_to :user, BetPeak.Accounts.User
    has_many :team, BetPeak.Teams.Team

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(sport, attrs, _opts) do
    sport
    |> cast(attrs, [:name, :description, :active, :user_id])
    |> validate_required([:name, :description, :active, :user_id])
    |> validate_length(:name, min: 2, max: 50)
    |> unique_constraint(:name,
      repo_opts: [where: "deleted_at IS NULL"],
      message: "is already taken"
    )
    |> validate_length(:description, min: 10, max: 200)
  end
end
