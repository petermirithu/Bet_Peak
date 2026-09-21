defmodule BetPeak.RolesFixtures do
  defp unique_role_name, do: "some name#{System.unique_integer([:positive])}"

  def get_valid_attributes() do
    %{
      name: unique_role_name()
    }
  end

  def get_invalid_attributes() do
    %{
      name: nil
    }
  end

  def add_roles(scope) do
    valid_active_1 = get_valid_attributes()
    valid_active_2 = get_valid_attributes()
    valid_active_3 = get_valid_attributes()

    BetPeak.Roles.save(scope, valid_active_1)
    BetPeak.Roles.save(scope, valid_active_2)
    BetPeak.Roles.save(scope, valid_active_3)
  end

  def add_role(scope) do
    {:ok, role} = BetPeak.Roles.save(scope, get_valid_attributes())
    role
  end
end
