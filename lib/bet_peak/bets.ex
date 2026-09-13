defmodule BetPeak.Bets do
  import Ecto.Query, warn: false

  alias BetPeak.Repo
  alias BetPeak.Bets.Bet
  alias BetPeak.Bets.BetNotifier
  alias BetPeak.Workers
  alias Oban

  def fetch_all() do
    from(bet in Bet, where: is_nil(bet.deleted_at))
    |> Repo.all()
  end

  def fetch_active(user_id) do
    from(bet in Bet,
      where: is_nil(bet.deleted_at) and bet.status == :pending and bet.user_id == ^user_id
    )
    |> Repo.all()
    |> Repo.preload(:game)
    |> Repo.preload(game: :home_team, game: :away_team)
  end

  def fetch_history(user_id) do
    bets =
      from(bet in Bet,
        where:
          is_nil(bet.deleted_at) and bet.user_id == ^user_id and
            bet.status in [:won, :lost, :cancelled]
      )
      |> Repo.all()
      |> Repo.preload(:game)
      |> Repo.preload(game: :home_team, game: :away_team)

    calculate_total_payouts(bets)
    |> Map.put(:bets, bets)
  end

  def fetch_admin_user_bets(user_id) do
    bets =
      from(bet in Bet, where: is_nil(bet.deleted_at) and bet.user_id == ^user_id)
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
          Map.put(acc, :lost, Decimal.add(acc.lost, bet.potential_payout))

        _ ->
          acc
      end
    end)
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

  def settle_game_bets(game_id, game_result) do
    max_stake_amount =
      Repo.one(
        from bet in Bet,
          where: is_nil(bet.deleted_at) and bet.game_id == ^game_id and bet.status == :pending,
          select: max(bet.stake_amount)
      ) || 0

    query =
      from(
        bet in Bet,
        where: is_nil(bet.deleted_at) and bet.game_id == ^game_id and bet.status == :pending
      )

    Repo.transaction(fn ->
      query
      |> Repo.stream()
      |> Stream.chunk_every(100)
      |> Enum.each(fn bets ->
        bets
        |> create_oban_jobs(max_stake_amount, game_result)
        |> Oban.insert_all()
      end)
    end)
  end

  defp create_oban_jobs(bets, max_stake_amount, game_result) do
    Enum.map(
      bets,
      fn bet ->
        ratio = Decimal.div(bet.stake_amount, max_stake_amount)

        oban_priority =
          cond do
            Decimal.gte?(ratio, Decimal.new("0.75")) -> 0
            Decimal.gte?(ratio, Decimal.new("0.50")) -> 1
            Decimal.gte?(ratio, Decimal.new("0.25")) -> 2
            true -> 3
          end

        Workers.SettleBet.new(
          %{bet_id: bet.id, game_result: game_result},
          priority: oban_priority
        )
      end
    )
  end

  def settle_bet_and_send_mail(bet_id, game_result) do
    bet =
      from(bet in Bet, where: is_nil(bet.deleted_at) and bet.id == ^bet_id)
      |> Repo.one()
      |> Repo.preload(:user)
      |> Repo.preload(:game)
      |> Repo.preload(game: :home_team)
      |> Repo.preload(game: :away_team)

    new_status = if(Atom.to_string(bet.selection) == game_result, do: :won, else: :lost)

    bet
    |> Ecto.Changeset.change(%{status: new_status})
    |> Repo.update!()
    |> send_betting_email()
  end

  defp send_betting_email(bet) do
    case bet.status do
      :won -> BetNotifier.send_bet_won_email(bet)
      :lost -> BetNotifier.send_bet_lost_email(bet)
    end
  end

  def delete_bet(%Bet{} = bet) do
    bet
    |> Ecto.Changeset.change(%{deleted_at: DateTime.utc_now() |> DateTime.truncate(:second)})
    |> Repo.update()
  end

  def delete_many_by_game_id(game_id) do
    from(bet in Bet, where: bet.game_id == ^game_id and is_nil(bet.deleted_at))
    |> Repo.update_all(set: [deleted_at: DateTime.utc_now() |> DateTime.truncate(:second)])
  end

  def delete_many_by_user_id(user_id) do
    from(bet in Bet, where: bet.user_id == ^user_id and is_nil(bet.deleted_at))
    |> Repo.update_all(set: [deleted_at: DateTime.utc_now() |> DateTime.truncate(:second)])
  end
end
