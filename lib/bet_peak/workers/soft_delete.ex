defmodule BetPeak.Workers.SoftDelete do
  use Oban.Worker, queue: :soft_delete, max_attempts: 3

  alias BetPeak.Bets
  alias BetPeak.Games
  alias BetPeak.Teams

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"table" => table, "id" => id}}) do
    case table do
      "bets" ->
        Bets.delete_many_by_game_id(id)

      "games" ->
        Games.delete_many_by_team_id(id)

      "teams" ->
        Teams.delete_many_by_sport_id(id)
    end

    :ok
  end

  def delete_children_records(changeset, table) do
    case changeset do
      {:ok, updated_record} ->
        %{table: table, id: updated_record.id}
        |> __MODULE__.new()
        |> Oban.insert()

        {:ok, updated_record}

      {:error, changeset} ->
        {:error, changeset}
    end
  end
end
