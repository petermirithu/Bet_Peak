defmodule BetPeak.RoleInheritsFixtures do
  alias BetPeak.Roles.Role
  alias BetPeak.Repo

  defp unique_string, do: "some unique str#{System.unique_integer([:positive])}"

  def create_role do
    {:ok, role} = %Role{name: unique_string()} |> Repo.insert()
    role
  end

  def get_valid_attributes(parent_role_id, child_role_id) do
    %{
      parent_role_id: parent_role_id,
      child_role_id: child_role_id
    }
  end

  def get_invalid_attributes() do
    %{
      parent_role_id: nil,
      child_role_id: nil
    }
  end

  def add_role_inherit(scope, parent_role_id, child_role_id) do
    {:ok, role_inherit} =
      BetPeak.RoleInherits.save(
        scope,
        get_valid_attributes(parent_role_id, child_role_id)
      )

    role_inherit
  end
end
