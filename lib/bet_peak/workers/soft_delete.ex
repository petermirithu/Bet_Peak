defmodule BetPeak.Workers.SoftDelete do
  use Oban.Worker, queue: :soft_delete, max_attempts: 3

  alias BetPeak.Bets

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"table" => table, "id" => id}}) do
    case table do
      "bets" ->
        Bets.delete_game_bets(id)
    end

    :ok
  end
end
