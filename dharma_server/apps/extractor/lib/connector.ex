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
  def start_link(name) do
    IO.puts("ADS >>> " <> inspect(name))
    server_name = String.to_atom(name)
    GenServer.start_link(__MODULE__, %{server_name: server_name}, [{:name, server_name}])
  end

  @doc """
  Callbacks for GenServer.Behaviour.
  """
  @impl true
  def init(state) do
    new_state = start_connection(state)
    GenServer.cast(new_state.server_name, :start)
    {:ok, new_state}
  end

  @impl true
  def handle_cast(:start, state) do
    GenServer.cast(
      state.server_name,
      {:send, state.server_name, Atom.to_string(state.server_name)}
    )

    :timer.sleep(2000)
    GenServer.cast(state.server_name, :start)
    {:noreply, state}
  end

  @doc """
  A send request, expects a source and a message.
  """
  @impl true
  def handle_cast({:send, source, message}, state) do
    routing = "insert.raw." <> Atom.to_string(source)
    send(routing, message, state.channel)
    {:noreply, state}
  end

  @doc """
  Closes the connection with RabbitMQ on exit.
  """
  @impl true
  def terminate(_reason, state) do
    close_connection(state.connection)
  end

  # Start a connection with RabbitMQ and declare an exchange.
  defp start_connection(state) do
    {:ok, connection} = AMQP.Connection.open()
    {:ok, channel} = AMQP.Channel.open(connection)
    AMQP.Exchange.declare(channel, "dharma", :topic)
    Map.merge(state, %{connection: connection, channel: channel})
  end

  # Publishes a message to an Exchange.
  @spec send(String.t(), String.t(), AMQP.Channel.t()) :: :ok
  defp send(topic, message, channel) do
    AMQP.Basic.publish(channel, "dharma", topic, message, persistent: true)
    IO.puts(" [x] Sent '[#{topic}] #{message}'")
  end

  # Close RabbitMQ connection.
  @spec close_connection(AMQP.Connection.t()) :: :ok | {:error, any()}
  defp close_connection(connection) do
    AMQP.Connection.close(connection)
  end
end
