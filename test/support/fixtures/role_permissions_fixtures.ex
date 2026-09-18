defmodule BetPeak.RolePermissionsFixtures do
  alias BetPeak.Resources.Resource
  alias BetPeak.Roles.Role
  alias BetPeak.Permissions.Permission
  alias BetPeak.Repo

  defp unique_string, do: "some unique str#{System.unique_integer([:positive])}"

  def create_permission do
    {:ok, permission} =
      %Permission{action: unique_string(), resource_id: hd(Repo.all(Resource)).id}
      |> Repo.insert()

    permission
  end

  def create_role do
    {:ok, role} = %Role{name: unique_string()} |> Repo.insert()
    role
  end

  def get_role_and_permission do
    {create_role(), create_permission()}
  end

  def get_valid_attributes(role_id, permission_id) do
    %{
      role_id: role_id,
      permission_id: permission_id
    }
  end

  def get_invalid_attributes() do
    %{
      role_id: nil,
      permission_id: nil
    }
  end

  def add_role_permissions(scope) do
    role = create_role()
    permission_1 = create_permission()
    permission_2 = create_permission()
    permission_3 = create_permission()

    valid_active_1 = get_valid_attributes(role.id, permission_1.id)
    valid_active_2 = get_valid_attributes(role.id, permission_2.id)
    valid_active_3 = get_valid_attributes(role.id, permission_3.id)

    BetPeak.RolePermissions.save(scope, valid_active_1)
    BetPeak.RolePermissions.save(scope, valid_active_2)
    BetPeak.RolePermissions.save(scope, valid_active_3)
  end

  def add_role_permission(scope, role_id, permission_id) do
    {:ok, role_permission} =
      BetPeak.RolePermissions.save(
        scope,
        get_valid_attributes(role_id, permission_id)
      )

    role_permission
  end
end
