defmodule Connector do
  @moduledoc """
  This is the `Connector` module.
  This module aims to receive raw data from
  external data sources and
  publish it to a RabbitMQ exchange.
  """

  @moduledoc since: "1.0.0"

  use GenServer
  @dharma_exchange Application.fetch_env!(:extractor, :rabbit_exchange)

  @doc """
  Convenience method for startup.
  """
  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(name) do
    server_name = String.to_atom(name)
    GenServer.start_link(__MODULE__, %{server_name: server_name}, [{:name, server_name}])
  end

  @doc """
  Callbacks for GenServer.Behaviour.
  """
  @impl true
  def init(state) do
    new_state = start_connection(state)
    simulate_external_message(new_state)
    {:ok, new_state}
  end

  defp simulate_external_message(state) do
    GenServer.cast(state.server_name, :send)
  end

  @impl true
  def handle_cast(:send, state) do
    GenServer.cast(
      state.server_name,
      {:send, state.server_name, Atom.to_string(state.server_name)}
    )

    :timer.sleep(2000)
    GenServer.cast(state.server_name, :send)
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
    url = Application.fetch_env!(:extractor, :rabbit_url)
    {:ok, connection} = AMQP.Connection.open(url)
    {:ok, channel} = AMQP.Channel.open(connection)
    AMQP.Exchange.declare(channel, @dharma_exchange, :topic)
    Map.merge(state, %{connection: connection, channel: channel})
  end

  # Publishes a message to an Exchange.
  @spec send(String.t(), String.t(), AMQP.Channel.t()) :: :ok
  defp send(topic, message, channel) do
    AMQP.Basic.publish(channel, @dharma_exchange, topic, message, persistent: true)
    IO.inspect("[#{topic}] #{message}", label: "[x] Sent")
  end

  # Close RabbitMQ connection.
  @spec close_connection(AMQP.Connection.t()) :: :ok | {:error, any()}
  defp close_connection(connection) do
    AMQP.Connection.close(connection)
  end
end
