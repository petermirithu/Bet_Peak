defmodule BetPeak.Sports do
  import Ecto.Query, warn: false

  alias BetPeak.Repo
  alias BetPeak.Sports.Sport
  alias BetPeak.Accounts.Scope

  def fetch_all() do
    Repo.all(Sport)
  end

  def get_sport(%Scope{} = scope, id) do
    Repo.get_by!(Sport, id: id, user_id: scope.user.id)
  end

  def save_sport(attrs) do
    %Sport{}
    |> Sport.changeset(attrs, [])
    |> Repo.insert()
  end

  def change_sport_creation(sport, attrs \\ %{}, opts \\ []) do
    Sport.changeset(sport, attrs, opts)
  end

  def update_sport(sport, attrs) do
    sport
    |> Sport.changeset(attrs, [])
    |> Repo.update()
  end

  def delete_sport(sport) do
    Repo.delete(sport)
  end
end
