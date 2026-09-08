defmodule BetPeak.TeamsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `BetPeak.Teams` context.
  """

  @doc """
  Generate a unique team name.
  """
  def unique_team_name, do: "some name#{System.unique_integer([:positive])}"

  @doc """
  Generate a unique team short_form.
  """
  def unique_team_short_form, do: "some short_form#{System.unique_integer([:positive])}"

  @doc """
  Generate a team.
  """
  def team_fixture(scope, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        name: unique_team_name(),
        short_form: unique_team_short_form()
      })

    {:ok, team} = BetPeak.Teams.create_team(scope, attrs)
    team
  end
end
