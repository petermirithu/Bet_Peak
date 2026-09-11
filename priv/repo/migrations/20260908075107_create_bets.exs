defmodule BetPeak.Repo.Migrations.CreateBets do
  use Ecto.Migration

  def change do
    create table(:bets) do
      add :selection, :string, null: false
      add :stake_amount, :decimal, null: false
      add :odds_at_placement, :decimal, null: false
      add :potential_payout, :decimal, null: false
      add :status, :string, null: false
      add :user_id, references(:users, on_delete: :delete_all)
      add :game_id, references(:games, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:bets, [:user_id])
    create index(:bets, [:game_id])
  end
end
