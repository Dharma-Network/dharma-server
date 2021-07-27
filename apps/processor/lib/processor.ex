defmodule Processor do
  use GenServer

  @moduledoc """
  A `Processor` handles info regarding one source of input.
  It reads data from a queue, processes that same data and forwards it to processed queues.
  """

  @dharma_exchange Application.fetch_env!(:processor, :rabbit_exchange)

  @doc """
  Starts a connection to handle one input source named `name`.
  """
  def start_link(name) do
    GenServer.start_link(__MODULE__, %{source: name}, [{:name, String.to_atom(name)}])
  end

  @impl true
  def init(state) do
    new_state = start_connection(state)
    {:ok, new_state}
  end

  # Creates the connection and the queues that will be used in the life cycle of this process.
  # After that, goes into a state where the process waits for messages.
  defp start_connection(state) do
    url = Application.fetch_env!(:processor, :rabbit_url)
    {:ok, connection} = AMQP.Connection.open(url)
    {:ok, channel} = AMQP.Channel.open(connection)
    AMQP.Exchange.declare(channel, @dharma_exchange, :topic)
    create_queue(channel, "raw_input", ["insert.raw." <> state.source])
    create_queue(channel, "process_dashboard", ["insert.processed.*"])

    create_queue(channel, "process_blockchain", [
      "insert.processed.dharma",
      "insert.processed.other"
    ])

    new_state = Map.put(state, :channel, channel)

    AMQP.Queue.subscribe(channel, "raw_input", fn payload, meta ->
      process_and_send(payload, meta, new_state)
    end)

    new_state
  end

  # Creates a queue named `queue_name` that's binded to each topic in the list.
  @spec create_queue(AMQP.Channel.t(), String.t(), [String.t()]) :: :ok
  defp create_queue(channel, queue_name, topics) do
    AMQP.Queue.declare(channel, queue_name, exclusive: false, durable: true)

    Enum.each(topics, fn x ->
      AMQP.Queue.bind(channel, queue_name, @dharma_exchange, routing_key: x)
    end)
  end

  # Process the payload and send it to the correct topic.
  defp process_and_send(payload, meta, state) do
    IO.inspect("[#{meta.routing_key}] #{payload}", label: "[x] Received")
    msg_processed = process(payload)
    # TODO: Dynamically select topics?
    send("insert.processed.dharma", msg_processed, state.channel)
  end

  # Processes the `message`, preparing it to be inserted in the processed queues.
  # Identity for now, will change later on!
  @spec process(any) :: any
  defp process(message) do
    message
  end

  # Sends a `message` in the exchange "dharma", in a certain channel, with a `topic`.
  @spec send(String.t(), any, AMQP.Channel.t()) :: :ok
  defp send(topic, message, channel) do
    AMQP.Basic.publish(channel, @dharma_exchange, topic, message)
    IO.inspect("[#{topic}] #{message}", label: "[x] Sent ")
  end

  @impl true
  def handle_info(_, state) do
    {:noreply, state}
  end
end
