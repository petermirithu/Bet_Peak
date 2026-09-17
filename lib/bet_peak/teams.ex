defmodule BetPeak.Teams do
  import Ecto.Query, warn: false
  alias BetPeak.Repo

  alias BetPeak.Teams.Team
  alias BetPeak.Workers
  alias BetPeak.Accounts.Scope
  alias BetPeak.Authorization

  def fetch_all(%Scope{} = current_scope) do
    case Authorization.authorize!(current_scope, "Teams", "read") do
      :ok ->
        from(team in Team, where: is_nil(team.deleted_at))
        |> Repo.all()
        |> Repo.preload(:sport)

      :unauthorized ->
        []
    end
  end

  def save_team(%Scope{} = current_scope, attrs) do
    case Authorization.authorize!(current_scope, "Teams", "create") do
      :ok ->
        %Team{}
        |> Team.changeset(attrs, [])
        |> Repo.insert()

      :unauthorized ->
        {:error, :unauthorized}
    end
  end

  def change_team_creation(team, attrs \\ %{}, opts \\ []) do
    Team.changeset(team, attrs, opts)
  end

  def update_team(%Scope{} = current_scope, team, attrs) do
    case Authorization.authorize!(current_scope, "Teams", "update") do
      :ok ->
        team
        |> Team.changeset(attrs, [])
        |> Repo.update()

      :unauthorized ->
        {:error, :unauthorized}
    end
  end

  def delete_team(%Scope{} = current_scope, team) do
    case Authorization.authorize!(current_scope, "Teams", "delete") do
      :ok ->
        team
        |> Ecto.Changeset.change(%{deleted_at: DateTime.utc_now() |> DateTime.truncate(:second)})
        |> Repo.update()
        |> Workers.SoftDelete.delete_children_records("team_games")

      :unauthorized ->
        {:error, :unauthorized}
    end
  end

  def delete_many_by_sport_id(sport_id) do
    # Oban Job
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
