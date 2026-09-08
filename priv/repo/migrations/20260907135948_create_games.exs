defmodule BetPeak.Repo.Migrations.CreateGames do
  use Ecto.Migration

  def change do
    create table(:games) do
      add :starts_at, :utc_datetime, null: false
      add :status, :string, null: false
      add :home_odds, :decimal, precision: 6, scale: 2, null: false
      add :away_odds, :decimal, precision: 6, scale: 2, null: false
      add :draw_odds, :decimal, precision: 6, scale: 2, null: false
      add :result, :string
      add :user_id, references(:users, on_delete: :delete_all)
      add :home_team_id, references(:teams, on_delete: :delete_all), null: false
      add :away_team_id, references(:teams, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:games, [:user_id])
    create index(:games, [:home_team_id])
    create index(:games, [:away_team_id])
  end
end
