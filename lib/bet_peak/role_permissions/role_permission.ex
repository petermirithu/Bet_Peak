defmodule BetPeak.RolePermissions.RolePermission do
  use Ecto.Schema
  import Ecto.Changeset

  schema "role_permissions" do
    belongs_to :role, BetPeak.Roles.Role
    belongs_to :permission, BetPeak.Permissions.Permission

    timestamps(type: :utc_datetime)
  end

  def changeset(role_permission, attrs, _opts) do
    role_permission
    |> cast(attrs, [:permission_id, :role_id])
    |> validate_required([:permission_id, :role_id])
    |> foreign_key_constraint(:role_id)
    |> foreign_key_constraint(:permission_id)
    |> unique_constraint([:permission_id, :role_id])
  end
end
