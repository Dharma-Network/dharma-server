defmodule Loader do
  use GenServer
  use Tesla

  adapter(Tesla.Adapter.Finch, name: MyFinch)

  @moduledoc """
  A `Processor` handles info regarding one source of input.
  It reads data from a queue, processes that same data and forwards it to processed queues.
  """

  @doc """
  Starts a connection to handle one input source named `name`.
  """
  def start_link(client) do
    GenServer.start_link(__MODULE__, %{client: client}, [{:name, __MODULE__}])
  end

  @impl true
  def init(state) do
    new_state = start_connection(state)
    {:ok, new_state}
  end

  # Creates the connection and the queues that will be used in the life cycle of this process.
  # After that, goes into a state where the process waits for messages.
  defp start_connection(state) do
    url = Application.fetch_env!(:rabbit, :url)
    {:ok, connection} = AMQP.Connection.open(url)
    {:ok, channel} = AMQP.Channel.open(connection)
    AMQP.Exchange.declare(channel, "dharma", :topic)

    create_queue(channel, "process_dashboard", ["insert.processed.*"])

    create_queue(channel, "process_blockchain", [
      "insert.processed.dharma",
      "insert.processed.other"
    ])

    new_state = Map.put(state, :channel, channel)

    AMQP.Queue.subscribe(channel, "process_dashboard", fn payload, meta ->
      send_data_couch(payload, meta, new_state)
    end)

    AMQP.Queue.subscribe(channel, "process_blockchain", fn payload, meta ->
      send_data_blockchain(payload, meta, new_state)
    end)

    new_state
  end

  # Creates a queue named `queue_name` that's binded to each topic in the list.
  @spec create_queue(AMQP.Channel.t(), String.t(), [String.t()]) :: :ok
  defp create_queue(channel, queue_name, topic) do
    AMQP.Queue.declare(channel, queue_name, exclusive: false, durable: true)

    Enum.each(topic, fn x ->
      AMQP.Queue.bind(channel, queue_name, "dharma", routing_key: x)
    end)
  end

  # Process the payload and send it to the correct topic.
  # TODO: Don't rely on couchdb UUID
  defp send_data_couch(payload, meta, state) do
    IO.puts(" [x] Received [#{meta.routing_key}] #{payload}")
    body = %{"topic" => meta.routing_key, "payload" => payload}
    res = post(state.client, "/dashboard", body)
    IO.inspect(res)
  end

  defp send_data_blockchain(_payload, _meta, _state) do
    :ok
  end

  @impl true
  def handle_info(_, state) do
    {:noreply, state}
  end
end
