defmodule Processor do
  @moduledoc """
  A `Processor` handles info regarding one source of input.
  It reads data from a queue, processes that same data and forwards it to processed queues.
  """

  @doc """
  Starts a connection to handle one input source named `name`.
  """
  def start_link(name) do
    start_connection(name)
  end

  @doc """
  Used by the supervisor to spawn this process.
  We opted to use as `id` the source from which data will be read.
  """
  @spec child_spec(String.t()) :: map()
  def child_spec(opts) do
    %{
      id: String.to_atom(opts),
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end

  # Creates the connection and the queues that will be used in the life cycle of this process.
  # After that, goes into a state where the process waits for messages.
  defp start_connection(source) do
    {:ok, connection} = AMQP.Connection.open
    {:ok, channel} = AMQP.Channel.open(connection)
    AMQP.Exchange.declare(channel, "dharma", :topic)
    create_queue(channel, "raw_input", ["insert.raw." <> source])
    create_queue(channel, "process_dashboard", ["insert.processed.*"])
    create_queue(channel, "process_blockchain", ["insert.processed.dharma", "insert.processed.other"])
    AMQP.Basic.consume(channel, "raw_input", nil)

    wait_for_messages(channel)
  end

  # Creates a queue named `queue_name` that's binded to each topic in the list.
  @spec create_queue(AMQP.Channel.t(), String.t(), [String.t()]) :: :ok
  defp create_queue(channel, queue_name, topic) do
    AMQP.Queue.declare(channel, queue_name , [durable: true, exclusive: true])
    Enum.each(topic, fn x ->
      AMQP.Queue.bind(channel, queue_name, "dharma", routing_key: x)
    end)
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
    AMQP.Basic.publish(channel, "dharma", topic, message, persistent: true)
    IO.puts " [x] Sent '[#{topic}] #{message}'"
  end

  # A loop that waits for messages in a `channel`, processes them and re-delivers them to the processed topic.
  defp wait_for_messages(channel) do
    receive do
      {:basic_deliver, payload, meta} ->
        IO.puts " [x] Received [#{meta.routing_key}] #{payload}"
        msg_processed = process(payload)
        send("insert.processed.*", msg_processed, channel)
        AMQP.Basic.ack(channel, meta.delivery_tag)
        wait_for_messages(channel)
    end
  end

end
