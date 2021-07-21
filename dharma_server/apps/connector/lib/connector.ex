defmodule Connector do
  @moduledoc """
  Documentation for `Connector`.
  """
  use GenServer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], [{:name, __MODULE__}])
  end

  @impl true
  def init([]) do
    pid = spawn(fn -> Extractor.loop  end)
    {connection, channel} = start_connection()
    #IO.puts "PID: #{inspect(pid)}"
    {:ok,{connection, channel, pid}}
  end

  @impl true
  def handle_call({:send, source, message}, _from, {_connection, channel, _pid} = state) do
    routing = "insert.raw." <> source
    send(routing, message, channel)
    {:reply, state, state}
  end

  @impl true
  def handle_call(:pid, _from, {_connection, _channel, pid} = state) do
    {:reply, pid, state}
  end

  defp start_connection do
    {:ok, connection} = AMQP.Connection.open
    {:ok, channel} = AMQP.Channel.open(connection)
    AMQP.Exchange.declare(channel, "dharma", :topic)
    {connection, channel}
  end

  defp send(topic, message, channel) do
    AMQP.Basic.publish(channel, "dharma", topic, message)
    IO.puts " [x] Sent '[#{topic}] #{message}'"
  end

  defp close_connection(connection) do
    AMQP.Connection.close(connection)
  end

end
