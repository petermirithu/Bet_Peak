defmodule BetPeak.Repo do
  use Ecto.Repo,
    otp_app: :bet_peak,
    adapter: Ecto.Adapters.Postgres
end
