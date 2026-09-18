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

  def add_role_permission(scope, role_id, permission_id) do
    {:ok, role_permission} =
      BetPeak.RolePermissions.save(
        scope,
        get_valid_attributes(role_id, permission_id)
      )

    role_permission
  end
end
