defmodule BetPeak.SportsFixtures do
  defp unique_sport_name, do: "some name#{System.unique_integer([:positive])}"

  def get_valid_attributes(user_id) do
    %{
      active: true,
      name: unique_sport_name(),
      description: "some description .....",
      user_id: user_id
    }
  end

  def get_invalid_attributes(user_id) do
    %{
      active: nil,
      name: nil,
      description: "some description .....",
      user_id: user_id
    }
  end

  def add_sports(scope) do
    valid_active_1 = get_valid_attributes(scope.user.id)
    valid_active_2 = get_valid_attributes(scope.user.id)
    valid_inactive_1 = get_valid_attributes(scope.user.id) |> Map.put(:active, false)

    BetPeak.Sports.save_sport(scope, valid_active_1)
    BetPeak.Sports.save_sport(scope, valid_active_2)
    BetPeak.Sports.save_sport(scope, valid_inactive_1)
  end

  def add_sport(scope) do
    {:ok, sport} = BetPeak.Sports.save_sport(scope, get_valid_attributes(scope.user.id))
    sport
  end
end
