defmodule BetPeakWeb.AdminLive.Index do
  use BetPeakWeb, :live_view

  alias BetPeakWeb.Helpers
  alias BetPeak.Accounts
  alias BetPeak.Sports
  alias BetPeak.Games
  alias BetPeak.Bets

  @impl true
  def mount(_params, _session, socket) do
    users = Accounts.get_all_users(socket.assigns.current_scope)

    IO.inspect(hd(users))

    bets = Bets.fetch_all(socket.assigns.current_scope)

    bet_stats =
      Enum.reduce(bets, %{profits: 0, losses: 0}, fn bet, acc ->
        case bet.status do
          :lost ->
            Map.put(acc, :profits, Decimal.add(acc.profits, bet.potential_payout))

          :won ->
            Map.put(acc, :losses, Decimal.add(acc.losses, bet.potential_payout))

          _ ->
            acc
        end
      end)

    stats = %{
      users: Enum.count(users),
      sports: Enum.count(Sports.fetch_all(socket.assigns.current_scope)),
      games: Enum.count(Games.fetch_all(socket.assigns.current_scope)),
      bets: Enum.count(bets),
      profits: bet_stats.profits,
      losses: bet_stats.losses
    }

    {:ok,
     socket
     |> assign(stats: stats)
     |> assign(recent_users: Enum.take(users, 5))}
  end

  def format_user_roles(user) do
    Enum.map(user.user_roles, fn user_role ->
      "#{user_role.role.name} "
    end)
  end
end
