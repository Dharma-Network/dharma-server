defmodule Extractor.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      %{
        id: Github,
        start: {Connector, :start_link, ["github"]}
      },
      %{
        id: Trello,
        start: {Connector, :start_link, ["trello"]}
      }
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Extractor.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
