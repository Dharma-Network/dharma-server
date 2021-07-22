defmodule Connector do
  @moduledoc """
  This is the `Connector` module.
  This module aims to receive raw data from
  external data sources and
  publish it to a RabbitMQ exchange.
  """

  @moduledoc since: "1.0.0"

  use GenServer

  @doc """
  Convenience method for startup.
  """
  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], [{:name, __MODULE__}])
  end

  @doc """
  Callbacks for GenServer.Behaviour.
  """
  @impl true
  def init([]) do
    {:ok, _pid} = Task.Supervisor.start_child(Connector.TaskSupervisor, fn -> Extractor.loop end, restart: :permanent)
    {connection, channel} = start_connection()
    {:ok,{connection, channel}}
  end

  @doc """
  A send request, expects a source and a message.
  """
  @impl true
  def handle_call({:send, source, message}, _from, {_connection, channel} = state) do
    routing = "insert.raw." <> source
    send(routing, message, channel)
    {:reply, state, state}
  end

  @doc """
  Closes the connection with RabbitMQ on exit.
  """
  @impl true
  def terminate(_reason, {connection, _channel}) do
    close_connection(connection)
  end

  # Start a connection with RabbitMQ and declare an exchange.
  defp start_connection do
    {:ok, connection} = AMQP.Connection.open
    {:ok, channel} = AMQP.Channel.open(connection)
    AMQP.Exchange.declare(channel, "dharma", :topic)
    {connection, channel}
  end

  # Publishes a message to an Exchange.
  @spec send(String.t, String.t, AMQP.Channel.t()) :: :ok
  defp send(topic, message, channel) do
    AMQP.Basic.publish(channel, "dharma", topic, message, persistent: true)
    IO.puts " [x] Sent '[#{topic}] #{message}'"
  end

  # Close RabbitMQ connection.
  @spec close_connection(AMQP.Connection.t()) :: :ok | {:error, any()}
  defp close_connection(connection) do
    AMQP.Connection.close(connection)
  end

end
