defmodule BetPeakWeb.UserSessionController do
  use BetPeakWeb, :controller

  alias BetPeak.Accounts
  alias BetPeakWeb.UserAuth

  def create(conn, %{"_action" => "confirmed"} = params) do
    confirm_user_account(conn, params, "Account confirmed successfully.")
  end

  def create(conn, params) do
    create(conn, params, "Welcome back!")
  end

  # confirm user account
  defp confirm_user_account(conn, %{"user" => user_params}, info) do
    %{"token" => token, "remember_me" => _remember_me} = user_params

    case Accounts.confirm_new_user_account(token) do
      {:ok, {user, _}} ->
        conn
        |> put_flash(:info, info)
        |> UserAuth.log_in_user(user, user_params)

      _ ->
        conn
        |> put_flash(:error, "Something went wrong while confirming your account.")
        |> redirect(to: ~p"/users/log-in")
    end
  end

  # email + password login
  defp create(conn, %{"user" => user_params}, info) do
    %{"email" => email, "password" => password} = user_params

    if user = Accounts.get_user_by_email_and_password(email, password) do
      conn
      |> put_flash(:info, info)
      |> UserAuth.log_in_user(user, user_params)
    else
      # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
      conn
      |> put_flash(:error, "Invalid email or password")
      |> put_flash(:email, String.slice(email, 0, 160))
      |> redirect(to: ~p"/users/log-in")
    end
  end

  def update_password(conn, %{"user" => user_params} = params) do
    case Accounts.update_user_password(conn.assigns.current_scope, user_params) do
      {:ok, {_user, expired_tokens}} ->
        # disconnect all existing LiveViews with old sessions
        UserAuth.disconnect_sessions(expired_tokens)

        conn
        |> put_session(:user_return_to, ~p"/users/settings")
        |> create(params, "Password updated successfully!")

      {:error, :unauthorized} ->
        conn
        |> put_session(:user_return_to, ~p"/users/settings")
        |> create(params, "You are not allowed to update the password!")
    end
  end

  def delete(conn, _params) do
    conn
    |> UserAuth.log_out_user()
    |> put_flash(:info, "Logged out successfully.")
  end
end
