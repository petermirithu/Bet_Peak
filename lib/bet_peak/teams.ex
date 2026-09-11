defmodule BetPeak.Teams do
  import Ecto.Query, warn: false
  alias BetPeak.Repo

  alias BetPeak.Teams.Team
  alias BetPeak.Workers

  def fetch_all() do
    from(team in Team, where: is_nil(team.deleted_at))
    |> Repo.all()
    |> Repo.preload(:sport)
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
    team
    |> Ecto.Changeset.change(%{deleted_at: DateTime.utc_now() |> DateTime.truncate(:second)})
    |> Repo.update()
    |> Workers.SoftDelete.delete_children_records("games")
  end
end
