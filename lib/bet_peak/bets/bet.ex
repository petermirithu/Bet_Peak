defmodule BetPeak.Bets.Bet do
  use Ecto.Schema
  import Ecto.Changeset

  alias BetPeak.Games

  schema "bets" do
    field :selection, Ecto.Enum, values: [:home, :draw, :away]
    field :stake_amount, :decimal
    field :odds_at_placement, :decimal
    field :potential_payout, :decimal

    field :status, Ecto.Enum,
      values: [:pending, :won, :lost, :cancelled],
      default: :pending

    field :deleted_at, :utc_datetime

    belongs_to :user, BetPeak.Accounts.User
    belongs_to :game, BetPeak.Games.Game

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(bet, attrs, _opts) do
    bet
    |> cast(attrs, [
      :selection,
      :stake_amount,
      :user_id,
      :game_id
    ])
    |> validate_required([
      :selection,
      :stake_amount,
      :game_id,
      :user_id
    ])
    |> validate_number(:stake_amount, greater_than: Decimal.new("100.0"))
    |> add_odds_at_placement()
    |> calculate_potential_payout()
  end

  defp add_odds_at_placement(changeset) do
    with selection when selection in [:home, :draw, :away] <- get_field(changeset, :selection),
         game_id when is_integer(game_id) <- get_field(changeset, :game_id),
         %{} = game <- Games.get_game_for_bets(game_id) do
      put_change(
        changeset,
        :odds_at_placement,
        odds_for(game, selection)
      )
    else
      _ -> changeset
    end
  end

  defp odds_for(%{home_odds: odds}, :home), do: odds
  defp odds_for(%{draw_odds: odds}, :draw), do: odds
  defp odds_for(%{away_odds: odds}, :away), do: odds

  defp calculate_potential_payout(changeset) do
    stake = get_field(changeset, :stake_amount)
    odds = get_field(changeset, :odds_at_placement)

    case {stake, odds} do
      {%Decimal{} = stake, %Decimal{} = odds} ->
        payout = Decimal.mult(stake, odds)
        put_change(changeset, :potential_payout, payout)

      _ ->
        changeset
    end
  end
end
