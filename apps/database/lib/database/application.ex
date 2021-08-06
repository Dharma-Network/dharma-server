defmodule Database.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    Finch.start_link(name: FinchAdapter)
    opts = [strategy: :one_for_one, name: Database.Supervisor]

    children = [
      {Database.Auth, []}
    ]

    Supervisor.start_link(children, opts)
  end
end
