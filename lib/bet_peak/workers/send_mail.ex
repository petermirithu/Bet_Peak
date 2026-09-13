defmodule BetPeak.Workers.SendMail do
  use Oban.Worker, queue: :send_mail, max_attempts: 3

  alias Swoosh.Email
  alias BetPeak.Mailer

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"recipient" => recipient, "subject" => subject, "body" => body}}) do
    email =
      Email.new(
        to: recipient,
        from: {"BetPeak", System.get_env("GMAIL_USER")},
        subject: subject,
        text_body: body
      )

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    else
      {:error, reason} ->
        {:error, reason}
    end

    :ok
  end

  def create_mail_job(recipient, subject, body) do
    %{
      recipient: recipient,
      subject: subject,
      body: body
    }
    |> __MODULE__.new()
    |> Oban.insert()
  end
end
