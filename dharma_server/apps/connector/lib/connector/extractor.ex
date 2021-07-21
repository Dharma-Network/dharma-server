defmodule Connector.Extractor do
  def loop(x \\ 0) do
    [source, message] =
      IO.gets("Source-Msg")
        |> String.trim
        |> String.split("-")

    GenServer.call(Connector.Connector, {:send, source, message})
    loop(x+1)
  end

end
