defmodule ExDesk.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ExDeskWeb.Telemetry,
      ExDesk.Repo,
      {DNSCluster, query: Application.get_env(:ex_desk, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: ExDesk.PubSub},
      # Start a worker by calling: ExDesk.Worker.start_link(arg)
      # {ExDesk.Worker, arg},
      # Start to serve requests, typically the last entry
      ExDeskWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ExDesk.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ExDeskWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
