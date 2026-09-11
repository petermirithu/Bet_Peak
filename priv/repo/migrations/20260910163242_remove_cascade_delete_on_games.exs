defmodule BetPeak.Repo.Migrations.RemoveCascadeDeleteOnGames do
  use Ecto.Migration

  def up do
    alter table(:games) do
      modify :user_id, references(:users, on_delete: :nothing),
        from: references(:users, on_delete: :delete_all)

      modify :home_team_id, references(:teams, on_delete: :nothing),
        from: references(:teams, on_delete: :delete_all)

      modify :away_team_id, references(:teams, on_delete: :nothing),
        from: references(:teams, on_delete: :delete_all)

      add :deleted_at, :utc_datetime
    end
  end

  def down do
    alter table(:games) do
      modify :user_id, references(:users, on_delete: :delete_all),
        from: references(:users, on_delete: :nothing)

      modify :home_team_id, references(:teams, on_delete: :delete_all),
        from: references(:teams, on_delete: :nothing)

      modify :away_team_id, references(:teams, on_delete: :delete_all),
        from: references(:teams, on_delete: :nothing)

      remove :deleted_at
    end
  end
end
