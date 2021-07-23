defmodule Processor.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    opts = [strategy: :one_for_one, name: Processor.Supervisor]

    children = [
      %{
        id: Git,
        start: {Processor, :start_link, ["github"]}
      },
      %{
        id: Trello,
        start: {Processor, :start_link, ["trello"]}
      }
    ]

    Supervisor.start_link(children, opts)
  end

  # TODO: Fix
  # Reads the children that must be spawned (to read from each source) from the environment.
  # Returns a list with tuples of {Processor, source} for each source read.
  @spec read_children :: [{atom(), String.t()}]
  defp read_children do
    Application.fetch_env!(:processor, :source)
    |> Enum.map(fn x -> {Processor, x} end)
  end
end
