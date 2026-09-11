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
    |> Workers.SoftDelete.delete_children_records("team_games")
  end

  def delete_many_by_sport_id(sport_id) do
    query =
      from(team in Team,
        where:
          team.sport_id == ^sport_id and
            is_nil(team.deleted_at)
      )

    query
    |> Repo.all()
    |> soft_delete_teams(query)
    |> Enum.each(fn team ->
      Workers.SoftDelete.delete_children_records({:ok, team}, "team_games")
    end)
  end

  defp soft_delete_teams(teams, query) do
    Repo.update_all(query, set: [deleted_at: DateTime.utc_now() |> DateTime.truncate(:second)])
    teams
  end
end
