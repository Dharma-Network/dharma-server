defmodule Processor do
  @moduledoc """
  Documentation for `Processor`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Processor.hello()
      :world

  """

  def start_link(name) do
    start_connection(name)
  end

  def child_spec(opts) do
    %{
      id: String.to_atom(opts),
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end

  defp start_connection(source) do
    {:ok, connection} = AMQP.Connection.open
    {:ok, channel} = AMQP.Channel.open(connection)
    AMQP.Exchange.declare(channel, "dharma", :topic)
    create_queue(channel, "raw_input", ["insert.raw." <> source])
    create_queue_no_consume(channel, "process_dashboard", ["insert.processed.*"])
    create_queue_no_consume(channel, "process_blockchain", ["insert.processed.dharma", "insert.processed.other"])

    wait_for_messages(channel)
  end

  defp create_queue(channel, queue_name, topic) do
    AMQP.Queue.declare(channel, queue_name , exclusive: true)
    Enum.each(topic, fn x ->
      AMQP.Queue.bind(channel, queue_name, "dharma", routing_key: x)
    end)
    AMQP.Basic.consume(channel, queue_name, nil, no_ack: true)
  end

  defp create_queue_no_consume(channel, queue_name, topic) do
    AMQP.Queue.declare(channel, queue_name , exclusive: true)
    Enum.each(topic, fn x ->
      AMQP.Queue.bind(channel, queue_name, "dharma", routing_key: x)
    end)
  end

  defp process(message) do
    message
  end

  defp send(topic, message, channel) do
    AMQP.Basic.publish(channel, "dharma", topic, message)
    IO.puts " [x] Sent '[#{topic}] #{message}'"
  end

  defp wait_for_messages(channel) do
    receive do
      {:basic_deliver, payload, meta} ->
        IO.puts " [x] Received [#{meta.routing_key}] #{payload}"
        msg_processed = process(payload)
        send("insert.processed.*", msg_processed, channel)
        wait_for_messages(channel)
    end
  end

end
