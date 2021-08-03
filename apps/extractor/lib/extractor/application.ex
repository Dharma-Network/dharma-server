defmodule Extractor.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    # Logger.remove_backend(:console)
    opts = [strategy: :one_for_one, name: Extractor.Supervisor]

    children = [
      {Extractor.Github, []}
      # {Extractor.Trello, client}
    ]

    Supervisor.start_link(children, opts)
  end
end
