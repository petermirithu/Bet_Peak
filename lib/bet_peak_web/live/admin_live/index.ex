defmodule BetPeakWeb.AdminLive.Index do
  use BetPeakWeb, :live_view

  alias BetPeakWeb.Helpers
  alias BetPeak.Accounts
  alias BetPeak.Sports
  alias BetPeak.Games
  alias BetPeak.Bets

  @impl true
  def mount(_params, _session, socket) do
    users = Accounts.get_all_users()
    bets = Bets.fetch_all()

    bet_stats =
      Enum.reduce(bets, %{profits: 0, losses: 0}, fn bet, acc ->
        case bet.status do
          :won ->
            Map.put(acc, :profits, Decimal.add(acc.profits, bet.potential_payout))

          :lost ->
            Map.put(acc, :losses, Decimal.add(acc.losses, bet.potential_payout))

          _ ->
            acc
        end
      end)

    stats = %{
      users: Enum.count(users),
      sports: Enum.count(Sports.fetch_all()),
      games: Enum.count(Games.fetch_all()),
      bets: Enum.count(bets),
      profits: bet_stats.profits,
      losses: bet_stats.losses
    }

    {:ok,
     socket
     |> assign(stats: stats)
     |> assign(recent_users: Enum.take(users, 5))}
  end
end
