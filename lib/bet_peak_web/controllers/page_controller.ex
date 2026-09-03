defmodule BetPeakWeb.PageController do
  use BetPeakWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
