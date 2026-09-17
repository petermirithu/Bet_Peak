defmodule BetPeakWeb.VerifyAccountController do
  use BetPeakWeb, :controller

  alias BetPeak.Accounts

  def index(conn, _params) do
    if conn.assigns[:current_scope].user.confirmed_at == nil &&
         Accounts.get_user_token_by_context(conn.assigns[:current_scope], "login") == [] do
      Accounts.deliver_login_instructions(
        conn.assigns[:current_scope],
        &url(~p"/users/log-in/#{&1}")
      )
    end

    render(conn, :index)
  end
end
