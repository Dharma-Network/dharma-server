defmodule Loader do
  use GenServer
  require Logger

  defp dharma_exchange, do: Application.fetch_env!(:loader, :rabbit_exchange)

  @moduledoc """
  This module redirects data from processed queues to database and blockchain.
  """

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, [{:name, __MODULE__}])
  end

  @impl true
  def init(state) do
    new_state = start_connection(state)
    {:ok, new_state}
  end

  # Creates the connection and the queues that will be used in the life cycle of this process.
  # After that, goes into a state where the process waits for messages.
  defp start_connection(state) do
    url = Application.fetch_env!(:loader, :rabbit_url)
    {:ok, connection} = AMQP.Connection.open(url)
    {:ok, channel} = AMQP.Channel.open(connection)
    AMQP.Exchange.declare(channel, dharma_exchange(), :topic)

    create_queue(channel, "process_dashboard", ["insert.processed.*"])

    create_queue(channel, "process_blockchain", [
      "insert.processed.dharma",
      "insert.processed.other"
    ])

    new_state = Map.put(state, :channel, channel)

    AMQP.Queue.subscribe(channel, "process_dashboard", fn payload, meta ->
      send_to_database(payload, meta)
    end)

    AMQP.Queue.subscribe(channel, "process_blockchain", fn payload, meta ->
      send_to_blockchain(payload, meta, new_state)
    end)

    new_state
  end

  # Creates a queue named `queue_name` that's binded to each topic in the list.
  @spec create_queue(AMQP.Channel.t(), String.t(), [String.t()]) :: :ok
  defp create_queue(channel, queue_name, topics) do
    AMQP.Queue.declare(channel, queue_name, exclusive: false, durable: true)

    Enum.each(topics, fn x ->
      AMQP.Queue.bind(channel, queue_name, dharma_exchange(), routing_key: x)
    end)
  end

  # Process the payload and send it to the correct topic.
  defp send_to_database(payload, meta) do
    Logger.info("[#{meta.routing_key}] #{payload}", label: "[x] Received ")

    Jason.decode!(payload)
    |> Map.put("uuid", UUID.uuid1())
    |> Database.post_to_db()
  end

  defp send_to_blockchain(_payload, _meta, _state) do
    :ok
  end

  @impl true
  def handle_info(_, state) do
    {:noreply, state}
  end
end
