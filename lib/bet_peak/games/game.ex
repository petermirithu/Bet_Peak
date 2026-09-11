defmodule BetPeak.Games.Game do
  use Ecto.Schema
  import Ecto.Changeset

  schema "games" do
    field :starts_at, :utc_datetime
    field :status, Ecto.Enum, values: [:scheduled, :live, :finished, :cancelled]
    field :home_odds, :decimal, default: 0.00
    field :away_odds, :decimal, default: 0.00
    field :draw_odds, :decimal, default: 0.00

    field :result, Ecto.Enum,
      values: [:pending, :home, :away, :draw],
      default: :pending

    field :deleted_at, :utc_datetime

    belongs_to :user, BetPeak.Accounts.User
    belongs_to :home_team, BetPeak.Teams.Team, foreign_key: :home_team_id
    belongs_to :away_team, BetPeak.Teams.Team, foreign_key: :away_team_id

    has_many :bets, BetPeak.Bets.Bet

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(game, attrs, _opts) do
    game
    |> cast(attrs, [
      :starts_at,
      :status,
      :home_odds,
      :away_odds,
      :draw_odds,
      :result,
      :user_id,
      :home_team_id,
      :away_team_id
    ])
    |> validate_required([
      :starts_at,
      :status,
      :home_odds,
      :away_odds,
      :draw_odds,
      :result,
      :user_id,
      :home_team_id,
      :away_team_id
    ])
    |> validate_starts_at_in_future()
    |> validate_home_away_team()
    |> validate_number(:home_odds, greater_than: Decimal.new("1.0"))
    |> validate_number(:away_odds, greater_than: Decimal.new("1.0"))
    |> validate_number(:draw_odds, greater_than: Decimal.new("1.0"))
    |> validate_status_result()
  end

  defp validate_starts_at_in_future(changeset) do
    validate_change(changeset, :starts_at, fn :starts_at, starts_at ->
      now = DateTime.utc_now()

      case DateTime.compare(starts_at, now) do
        :gt -> []
        _ -> [starts_at: "must be in the future"]
      end
    end)
  end

  defp validate_home_away_team(changeset) do
    home_team_id = get_field(changeset, :home_team_id)
    away_team_id = get_field(changeset, :away_team_id)

    if home_team_id && away_team_id && home_team_id == away_team_id do
      add_error(changeset, :away_team_id, "Home team and away team cannot be the same team.")
    else
      changeset
    end
  end

  defp validate_status_result(changeset) do
    status = get_field(changeset, :status)
    result = Map.get(changeset.changes, :result, Map.get(changeset.data, :result, :pending))

    case {status, result} do
      {:finished, :pending} ->
        add_error(changeset, :status, "Game can't be finished and result is Pending")

      _ ->
        changeset
    end
  end
end
