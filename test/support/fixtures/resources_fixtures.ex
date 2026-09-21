defmodule BetPeak.ResourcesFixtures do
  defp unique_resource_name, do: "some name#{System.unique_integer([:positive])}"

  def get_valid_attributes() do
    %{
      name: unique_resource_name()
    }
  end

  def get_invalid_attributes() do
    %{
      name: nil
    }
  end

  def add_resources(scope) do
    valid_active_1 = get_valid_attributes()
    valid_active_2 = get_valid_attributes()
    valid_active_3 = get_valid_attributes()

    BetPeak.Resources.save(scope, valid_active_1)
    BetPeak.Resources.save(scope, valid_active_2)
    BetPeak.Resources.save(scope, valid_active_3)
  end

  def add_resource(scope) do
    {:ok, resource} = BetPeak.Resources.save(scope, get_valid_attributes())
    resource
  end
end
