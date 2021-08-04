defmodule Loader.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    Logger.remove_backend(:console)

    children = [
      {Loader, []}
    ]

    opts = [strategy: :one_for_one, name: Loader.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
