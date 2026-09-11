defmodule BetPeak.Repo.Migrations.RemoveCascadeDeleteOnBets do
  use Ecto.Migration

  def up do
    alter table(:bets) do
      modify :user_id, references(:users, on_delete: :nothing),
        from: references(:users, on_delete: :delete_all)

      modify :game_id, references(:games, on_delete: :nothing),
        from: references(:games, on_delete: :delete_all)

      add :deleted_at, :utc_datetime
    end
  end

  def down do
    alter table(:bets) do
      modify :user_id, references(:users, on_delete: :delete_all),
        from: references(:users, on_delete: :nothing)

      modify :game_id, references(:games, on_delete: :delete_all),
        from: references(:games, on_delete: :nothing)

      remove :deleted_at
    end
  end
end
