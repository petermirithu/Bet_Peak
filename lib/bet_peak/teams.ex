defmodule BetPeak.Teams do
  import Ecto.Query, warn: false
  alias BetPeak.Repo

  alias BetPeak.Teams.Team
  alias BetPeak.Accounts.Scope

  def fetch_all() do
    Team
    |> Repo.all()
    |> Repo.preload(:sport)
  end

  def get_team(%Scope{} = scope, id) do
    Repo.get_by!(Team, id: id, user_id: scope.user.id)
  end

  def save_team(attrs) do
    %Team{}
    |> Team.changeset(attrs, [])
    |> Repo.insert()
  end

  def change_team_creation(team, attrs \\ %{}, opts \\ []) do
    Team.changeset(team, attrs, opts)
  end

  def update_team(team, attrs) do
    team
    |> Team.changeset(attrs, [])
    |> Repo.update()
  end

  def delete_team(team) do
    Repo.delete(team)
  end
end
