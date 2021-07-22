defmodule Connector.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Starts a worker by calling:
      # Connector.Worker.start_link(arg)
      {Task.Supervisor, name: Connector.TaskSupervisor},
      {Connector, []}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Connector.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
