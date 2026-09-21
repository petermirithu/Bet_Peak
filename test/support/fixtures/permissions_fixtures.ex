defmodule BetPeak.PermissionsFixtures do
  alias BetPeak.Resources.Resource
  alias BetPeak.Repo

  defp unique_permission_action, do: "some name#{System.unique_integer([:positive])}"

  def get_resource do
    hd(Repo.all(Resource))
  end

  def get_valid_attributes(resource_id) do
    %{
      action: unique_permission_action(),
      resource_id: resource_id
    }
  end

  def get_invalid_attributes() do
    %{
      action: nil,
      resource_id: nil
    }
  end

  def add_permissions(scope) do
    resource = get_resource()

    valid_active_1 = get_valid_attributes(resource.id)
    valid_active_2 = get_valid_attributes(resource.id)
    valid_active_3 = get_valid_attributes(resource.id)

    BetPeak.Permissions.save(scope, valid_active_1)
    BetPeak.Permissions.save(scope, valid_active_2)
    BetPeak.Permissions.save(scope, valid_active_3)
  end

  def add_permission(scope) do
    resource = get_resource()
    {:ok, permission} = BetPeak.Permissions.save(scope, get_valid_attributes(resource.id))
    permission
  end
end
