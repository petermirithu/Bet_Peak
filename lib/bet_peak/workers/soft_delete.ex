defmodule BetPeak.Workers.SoftDelete do
  use Oban.Worker, queue: :soft_delete, max_attempts: 3

  alias BetPeak.Bets
  alias BetPeak.Games
  alias BetPeak.Teams

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"relationship" => relationship, "id" => id}}) do
    case relationship do
      "game_bets" ->
        Bets.delete_many_by_game_id(id)

      "user_bets" ->
        Bets.delete_many_by_user_id(id)

      "team_games" ->
        Games.delete_many_by_team_id(id)

      "sport_teams" ->
        Teams.delete_many_by_sport_id(id)
    end

    :ok
  end

  def delete_children_records(changeset, relationship) do
    case changeset do
      {:ok, updated_record} ->
        %{
          relationship: relationship,
          id: updated_record.id
        }
        |> __MODULE__.new()
        |> Oban.insert()

        {:ok, updated_record}

      {:error, changeset} ->
        {:error, changeset}
    end
  end
end
