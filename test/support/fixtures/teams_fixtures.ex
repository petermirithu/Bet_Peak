defmodule BetPeak.TeamsFixtures do
  alias BetPeak.Repo
  alias BetPeak.Sports.Sport

  defp unique_string, do: "some name#{System.unique_integer([:positive])}"

  defp unique_short_code do
    10
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64(padding: false)
    |> String.slice(0, 3)
  end

  def get_valid_attributes(user_id, sport_id) do
    %{
      name: unique_string(),
      short_form: unique_short_code(),
      about: "some description .....",
      user_id: user_id,
      sport_id: sport_id
    }
  end

  def get_invalid_attributes() do
    %{
      name: nil,
      short_form: nil,
      about: "some description .....",
      user_id: nil,
      sport_id: nil
    }
  end

  def create_sport(user_id) do
    {:ok, sport} =
      %Sport{
        active: true,
        name: unique_string(),
        description: "some description .....",
        user_id: user_id
      }
      |> Repo.insert()

    sport
  end

  def add_teams(scope, sport_id) do
    valid_active_1 = get_valid_attributes(scope.user.id, sport_id)
    valid_active_2 = get_valid_attributes(scope.user.id, sport_id)
    valid_active_3 = get_valid_attributes(scope.user.id, sport_id)

    {:ok, team_1} = BetPeak.Teams.save_team(scope, valid_active_1)
    {:ok, team_2} = BetPeak.Teams.save_team(scope, valid_active_2)
    {:ok, team_3} = BetPeak.Teams.save_team(scope, valid_active_3)

    [team_1, team_2, team_3]
  end

  def add_team(scope, sport_id) do
    {:ok, team} = BetPeak.Teams.save_team(scope, get_valid_attributes(scope.user.id, sport_id))
    team
  end
end
