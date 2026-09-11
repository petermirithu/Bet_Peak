defmodule BetPeak.Repo.Migrations.RemoveCascadeDeleteOnUsers do
  use Ecto.Migration

  def up do
    alter table(:users) do
      add :deleted_at, :utc_datetime
    end
  end

  def down do
    alter table(:sports) do
      remove :deleted_at
    end
  end
end
