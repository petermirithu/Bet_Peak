defmodule BetPeakWeb.Helpers do
  # Contains helper functions for the whole application

  def user_initials(user) do
    [user.first_name, user.last_name]
    |> Enum.filter(&(is_binary(&1) and &1 != ""))
    |> Enum.map_join(&String.first/1)
    |> case do
      "" -> user.email |> String.first() |> String.upcase()
      initials -> String.upcase(initials)
    end
  end

  def format_date(%DateTime{} = date), do: Calendar.strftime(date, "%d %b %Y")
  def format_date(%NaiveDateTime{} = date), do: Calendar.strftime(date, "%d %b %Y")
end
