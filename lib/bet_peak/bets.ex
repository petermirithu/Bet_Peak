defmodule BetPeak.Bets do
  import Ecto.Query, warn: false

  alias BetPeak.Repo
  alias BetPeak.Bets.Bet
  alias BetPeak.Accounts.Scope
  alias BetPeak.Bets.BetNotifier

  def fetch_active(user_id) do
    Bet
    |> Repo.all_by(status: :pending, user_id: user_id)
    |> Repo.preload(:game)
    |> Repo.preload(game: :home_team, game: :away_team)
  end

  def fetch_history(user_id) do
    bets =
      from(bet in Bet, where: bet.user_id == ^user_id and bet.status in [:won, :lost, :cancelled])
      |> Repo.all()
      |> Repo.preload(:game)
      |> Repo.preload(game: :home_team, game: :away_team)

    calculate_total_payouts(bets)
    |> Map.put(:bets, bets)
  end

  defp calculate_total_payouts(bets) do
    Enum.reduce(bets, %{won: Decimal.new("0.0"), lost: Decimal.new("0.0")}, fn bet, acc ->
      case bet.status do
        :won ->
          Map.put(acc, :won, Decimal.add(acc.won, bet.potential_payout))

        :lost ->
          Map.put(acc, :lost, Decimal.add(acc.won, bet.potential_payout))
      end
    end)
  end

  def get_bet(%Scope{} = scope, id) do
    Repo.get_by!(Bet, id: id, user_id: scope.user.id)
  end

  def save_bet(attrs) do
    %Bet{}
    |> Bet.changeset(attrs, [])
    |> Repo.insert()
  end

  def change_bet_creation(bet, attrs \\ %{}, opts \\ []) do
    Bet.changeset(bet, attrs, opts)
  end

  def update_bet(bet, attrs) do
    bet
    |> Bet.changeset(attrs, [])
    |> Repo.update()
  end

  def settle_game_bets(game_id, selection) do
    # Query to update bets won
    Bet
    |> Repo.all_by(game_id: game_id, status: :pending)
    |> Repo.preload(:user)
    |> Repo.preload(:game)
    |> Repo.preload(game: :home_team)
    |> Repo.preload(game: :away_team)
    |> update_bets_won_and_lost(selection)
  end

  defp update_bets_won_and_lost(bets, selection) do
    # Update bets won
    bets
    |> Enum.filter(&(&1.selection == selection))
    |> update_bets_won()
    |> Enum.each(fn bet -> BetNotifier.send_bet_won_email(bet) end)

    # Update bets lost
    bets
    |> Enum.filter(&(&1.selection != selection))
    |> update_bets_lost()
    |> Enum.each(fn bet -> BetNotifier.send_bet_lost_email(bet) end)
  end

  defp update_bets_won(bets) do
    from(bet in Bet, where: bet.id in ^Enum.map(bets, & &1.id))
    |> Repo.update_all(set: [status: :won, updated_at: DateTime.utc_now()])

    bets
  end

  defp update_bets_lost(bets) do
    from(bet in Bet, where: bet.id in ^Enum.map(bets, & &1.id))
    |> Repo.update_all(set: [status: :lost, updated_at: DateTime.utc_now()])

    bets
  end

  def delete_bet(bet) do
    Repo.delete(bet)
  end
end
