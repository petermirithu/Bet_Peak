defmodule BetPeak.Repo.Migrations.RemoveCascadeDeleteOnSports do
  use Ecto.Migration

  def up do
    alter table(:sports) do
      modify :user_id, references(:users, on_delete: :nothing),
        from: references(:users, on_delete: :delete_all)

      add :deleted_at, :utc_datetime
    end
  end

  def down do
    alter table(:sports) do
      modify :user_id, references(:users, on_delete: :delete_all),
        from: references(:users, on_delete: :nothing)

      remove :deleted_at
    end
  end
end
