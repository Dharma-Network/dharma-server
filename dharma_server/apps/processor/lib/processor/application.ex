defmodule Processor.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Processor.Supervisor]
    read_children() |> Supervisor.start_link(opts)
  end

  defp read_children do
    Application.fetch_env!(:processor, :source)
    |> Enum.map(fn x -> {Processor, x} end)
  end

end
