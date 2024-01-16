defmodule GroveOfWisps.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      GroveOfWispsWeb.Telemetry,
      GroveOfWisps.Repo,
      {DNSCluster, query: Application.get_env(:grove_of_wisps, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: GroveOfWisps.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: GroveOfWisps.Finch},
      # Start a worker by calling: GroveOfWisps.Worker.start_link(arg)
      # {GroveOfWisps.Worker, arg},
      # Start to serve requests, typically the last entry
      GroveOfWispsWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: GroveOfWisps.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    GroveOfWispsWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
