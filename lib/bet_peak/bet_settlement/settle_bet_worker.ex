defmodule BetPeak.BetSettlement.SettleBetWorker do
  use Oban.Worker, queue: :bet_settlements, max_attempts: 3

  alias BetPeak.Bets

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"bet_id" => bet_id, "game_result" => game_result}}) do
    Bets.settle_bet_and_send_mail(bet_id, game_result)
    :ok
  end
end
