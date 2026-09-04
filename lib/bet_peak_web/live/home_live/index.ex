defmodule BetPeakWeb.HomeLive.Index do
  use BetPeakWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end
end
