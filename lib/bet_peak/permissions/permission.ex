defmodule BetPeak.Permissions.Permission do
  use Ecto.Schema
  import Ecto.Changeset

  schema "permissions" do
    field :action, :string

    belongs_to :resource, BetPeak.Resources.Resource

    has_many :role_permissions, BetPeak.RolePermissions.RolePermission

    many_to_many :roles, BetPeak.Roles.Role, join_through: BetPeak.RolePermissions.RolePermission

    timestamps(type: :utc_datetime)
  end

  def changeset(permission, attrs, _opts) do
    permission
    |> cast(attrs, [:action, :resource_id])
    |> validate_required([:action, :resource_id])
    |> validate_length(:action, min: 2, max: 50)
    |> unique_constraint(:action)
    |> foreign_key_constraint(:resource_id)
    |> unique_constraint([:action, :resource_id])
  end
end
