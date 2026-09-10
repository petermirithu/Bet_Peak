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
      :status,
      :user_id,
      :game_id
    ])
    |> validate_required([
      :selection,
      :stake_amount,
      :status,
      :game_id,
      :user_id
    ])
    |> validate_number(:stake_amount, greater_than: Decimal.new("100.0"))
    |> add_odds_at_placement()
    |> calculate_potential_payout()
  end

  defp add_odds_at_placement(changeset) do
    selection = get_field(changeset, :selection)

    if selection do
      game = Games.get_game(get_field(changeset, :game_id))

      put_change(
        changeset,
        :odds_at_placement,
        Map.get(game, String.to_atom("#{selection}_odds"), 0.0)
      )
    else
      changeset
    end
  end

  defp calculate_potential_payout(changeset) do
    stake_amount = get_field(changeset, :stake_amount)
    odds_at_placement = get_field(changeset, :odds_at_placement)

    if stake_amount do
      put_change(
        changeset,
        :potential_payout,
        Decimal.mult(stake_amount, odds_at_placement)
      )
    else
      changeset
    end
  end
end
