defmodule BetPeak.Bets do
  import Ecto.Query, warn: false

  alias BetPeak.Repo
  alias BetPeak.Bets.Bet
  alias BetPeak.Accounts.Scope

  def fetch_all() do
    Bet
    |> Repo.all()
    |> Repo.preload(:game)
    |> Repo.preload(game: :home_team, game: :away_team)
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

  def delete_bet(bet) do
    Repo.delete(bet)
  end
end
