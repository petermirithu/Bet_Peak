defmodule BetPeakWeb.Plugs.AdminProtected do
  import Plug.Conn
  import Phoenix.Controller

  alias BetPeak.Authorization

  def init(opts), do: opts

  def call(%Plug.Conn{} = conn, _opts) do
    case Authorization.authorize!(conn.assigns[:current_scope], "Admin Routes", "read") do
      :ok ->
        conn

      :unauthorized ->
        conn
        |> put_flash(:error, "You are not authorized to access that page.")
        |> redirect(to: "/")
        |> halt()
    end
  end
end
