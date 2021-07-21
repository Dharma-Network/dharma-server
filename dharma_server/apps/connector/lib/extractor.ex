defmodule Extractor do
  @moduledoc """
  The purpose of this module is to fetch data from external sources such as github, trello and jira.
  """

  @doc """
  The loop function reads a string from the stdin and parses it in order to send it to the Connector module.
  The behaviour of this function is expected to change since the goal here is to later read data from external sources.
  """
  def loop() do
    [source, message] =
      IO.gets("Source-Msg\n")
      |> String.trim()
      |> String.split("-")

    GenServer.call(Connector, {:send, source, message})
    loop()
  end
end
