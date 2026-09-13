defmodule BetPeak.Sports do
  import Ecto.Query, warn: false

  alias BetPeak.Repo
  alias BetPeak.Sports.Sport
  alias BetPeak.Workers
  alias BetPeak.Accounts.Scope
  alias BetPeak.Guards

  def fetch_all() do
    from(sport in Sport, where: is_nil(sport.deleted_at))
    |> Repo.all()
  end

  def save_sport(%Scope{} = scope, attrs) do
    case Guards.require_super_admin(true, scope.user) do
      :authorized ->
        %Sport{}
        |> Sport.changeset(attrs, [])
        |> Repo.insert()

      :unauthorized ->
        {:error, :not_authorized}
    end
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
    sport
    |> Ecto.Changeset.change(%{deleted_at: DateTime.utc_now() |> DateTime.truncate(:second)})
    |> Repo.update()
    |> Workers.SoftDelete.delete_children_records("sport_teams")
  end
end
