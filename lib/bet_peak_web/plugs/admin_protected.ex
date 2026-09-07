defmodule BetPeakWeb.Plugs.AdminProtected do
  import Plug.Conn
  import Phoenix.Controller

  def init(opts), do: opts

  def call(%Plug.Conn{} = conn, _opts) do
    if conn.assigns[:current_scope].user.role != :admin do
      conn
      |> put_flash(:info, "You are not authorized to access that page!")
      |> redirect(to: "/")
      |> halt()
    else
      conn
    end
  end
end
