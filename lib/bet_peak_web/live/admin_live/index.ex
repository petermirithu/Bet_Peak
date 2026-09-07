defmodule BetPeakWeb.AdminLive.Index do
  use BetPeakWeb, :live_view

  alias BetPeak.Accounts
  alias BetPeakWeb.Helpers

  @impl true
  def mount(_params, _session, socket) do
    users = Accounts.get_all_users()

    stats = %{
      total: length(users),
      verified: Enum.count(users, & &1.confirmed_at),
      admins: Enum.count(users, &(&1.role == :admin)),
      pending: Enum.count(users, &is_nil(&1.confirmed_at))
    }

    {:ok,
     socket
     |> assign(stats: stats)
     |> assign(recent_users: Enum.take(users, 5))}
  end
end
