defmodule BetPeak.Accounts.UserNotifier do
  alias BetPeak.Accounts.User
  alias BetPeak.Workers.SendMail

  def deliver_update_email_instructions(user, url) do
    SendMail.create_mail_job(user.email, "Update email instructions", """
    Hi #{user.email},

    You can change your email by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    Warm regards,
    Bet Peak Team
    """)
  end

  def deliver_login_instructions(user, url) do
    case user do
      %User{confirmed_at: nil} -> deliver_confirmation_instructions(user, url)
      _ -> deliver_magic_link_instructions(user, url)
    end
  end

  defp deliver_magic_link_instructions(user, url) do
    SendMail.create_mail_job(user.email, "Log in instructions", """
    Hi #{user.email},

    You can log into your account by visiting the URL below:

    #{url}

    If you didn't request this email, please ignore this.

    Warm regards,
    Bet Peak Team
    """)
  end

  defp deliver_confirmation_instructions(user, url) do
    SendMail.create_mail_job(user.email, "Confirmation instructions", """
    Hi #{user.email},

    You can confirm your account by visiting the URL below:

    #{url}

    If you didn't create an account with us, please ignore this.

    Warm regards,
    Bet Peak Team
    """)
  end
end
