defmodule BetPeak.Roles.Role do
  use Ecto.Schema
  import Ecto.Changeset

  alias BetPeak.RolePermissions.RolePermission

  schema "roles" do
    field :name, :string
    field :effective_permission_count, :integer, virtual: true, default: 0

    has_many :user_roles, BetPeak.UserRoles.UserRole
    has_many :role_permissions, RolePermission

    has_many :parent_inheritances, BetPeak.RoleInherits.RoleInherit, foreign_key: :child_role_id

    has_many :child_inheritances, BetPeak.RoleInherits.RoleInherit, foreign_key: :parent_role_id

    many_to_many :permissions, BetPeak.Permissions.Permission, join_through: RolePermission

    many_to_many :users, BetPeak.Accounts.User, join_through: BetPeak.UserRoles.UserRole

    timestamps(type: :utc_datetime)
  end

  def changeset(role, attrs, _opts) do
    role
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> validate_length(:name, min: 2, max: 50)
    |> unique_constraint(:name)
  end
end
