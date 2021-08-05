defmodule Extractor.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    opts = [strategy: :one_for_one, name: Extractor.Supervisor]

    children = [
      {Extractor.Github, []}
      # {Extractor.Trello, client}
    ]

    Supervisor.start_link(children, opts)
  end
end
