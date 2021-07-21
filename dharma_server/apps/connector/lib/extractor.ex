defmodule Extractor do
  def loop() do
    [source, message] =
      IO.gets("Source-Msg\n")
        |> String.trim
        |> String.split("-")
    GenServer.call(Connector, {:send, source, message})
    loop()
  end

end
