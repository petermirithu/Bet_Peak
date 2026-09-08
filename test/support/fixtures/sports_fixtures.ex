defmodule BetPeak.SportsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `BetPeak.Sports` context.
  """

  @doc """
  Generate a unique sport name.
  """
  def unique_sport_name, do: "some name#{System.unique_integer([:positive])}"

  @doc """
  Generate a unique sport slug.
  """
  def unique_sport_slug, do: "some slug#{System.unique_integer([:positive])}"

  @doc """
  Generate a sport.
  """
  def sport_fixture(scope, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        active: true,
        description: "some description",
        name: unique_sport_name(),
        slug: unique_sport_slug()
      })

    {:ok, sport} = BetPeak.Sports.create_sport(scope, attrs)
    sport
  end
end
