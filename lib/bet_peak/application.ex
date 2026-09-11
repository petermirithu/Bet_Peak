defmodule BetPeak.Application do
  # See https://elixir.hexdocs.pm/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      BetPeakWeb.Telemetry,
      BetPeak.Repo,
      {Oban, Application.fetch_env!(:bet_peak, Oban)},
      {DNSCluster, query: Application.get_env(:bet_peak, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: BetPeak.PubSub},
      # Start a worker by calling: BetPeak.Worker.start_link(arg)
      # {BetPeak.Worker, arg},
      # Start to serve requests, typically the last entry
      BetPeakWeb.Endpoint
    ]

    # See https://elixir.hexdocs.pm/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: BetPeak.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    BetPeakWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
