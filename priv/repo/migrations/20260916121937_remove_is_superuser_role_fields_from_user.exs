defmodule BetPeak.Repo.Migrations.RemoveIsSuperuserRoleFieldsFromUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      remove :role
      remove :is_superuser
    end
  end
end
