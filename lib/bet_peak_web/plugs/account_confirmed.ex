defmodule BetPeakWeb.Plugs.AccountConfirmed do
  import Plug.Conn
  import Phoenix.Controller
  alias BetPeak.Accounts

  def init(opts), do: opts

  def call(%Plug.Conn{} = conn, _opts) do
    case Accounts.check_if_confirmed(conn.assigns[:current_scope].user) do
      {:ok, :not_confirmed} ->
        conn
        |> put_flash(:info, "Please check your email out successfully.")
        |> redirect(to: "/users/verify_account")
        |> halt()

      _ ->
        conn
    end
  end
end
