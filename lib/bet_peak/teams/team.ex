defmodule BetPeak.Teams.Team do
  use Ecto.Schema
  import Ecto.Changeset

  schema "teams" do
    field :name, :string
    field :short_form, :string
    field :about, :string
    field :deleted_at, :utc_datetime

    belongs_to :user, BetPeak.Accounts.User
    belongs_to :sport, BetPeak.Sports.Sport

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(team, attrs, _opts) do
    team
    |> cast(attrs, [:name, :short_form, :about, :user_id, :sport_id])
    |> validate_required([:name, :short_form, :about, :user_id, :sport_id])
    |> validate_length(:name, min: 2)
    |> validate_length(:short_form, min: 2, max: 15)
    |> validate_length(:about, min: 10)
    |> unique_constraint(:short_form)
    |> unique_constraint(:name)
  end
end
