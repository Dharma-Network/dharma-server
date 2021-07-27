defmodule Extractor.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    opts = [strategy: :one_for_one, name: Extractor.Supervisor]

    read_children()
    |> Supervisor.start_link(opts)
  end

  # Reads the children that must be spawned (to read from each source) from the environment.
  # Returns a list with tuples of {Processor, source} for each source read.
  @spec read_children :: [{atom(), String.t()}]
  defp read_children do
    Application.fetch_env!(:extractor, :source)
    |> Enum.map(fn x ->
      %{
        id: x,
        start: {Connector, :start_link, [x]}
      }
    end)
  end
end
