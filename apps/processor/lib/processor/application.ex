defmodule Processor.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    opts = [strategy: :one_for_one, name: Processor.Supervisor]
    children = [
      {Processor, []},
      {Processor.Listener, []}
    ]

    Supervisor.start_link(children, opts)
  end
end
