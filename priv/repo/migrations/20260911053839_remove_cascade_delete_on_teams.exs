defmodule BetPeak.Repo.Migrations.RemoveCascadeDeleteOnTeams do
  use Ecto.Migration

  def up do
    alter table(:teams) do
      modify :user_id, references(:users, on_delete: :nothing),
        from: references(:users, on_delete: :delete_all)

      modify :sport_id, references(:sports, on_delete: :nothing),
        from: references(:sports, on_delete: :delete_all)

      add :deleted_at, :utc_datetime
    end
  end

  def down do
    alter table(:teams) do
      modify :user_id, references(:users, on_delete: :delete_all),
        from: references(:users, on_delete: :nothing)

      modify :sport_id, references(:sports, on_delete: :delete_all),
        from: references(:sports, on_delete: :nothing)

      remove :deleted_at
    end
  end
end
