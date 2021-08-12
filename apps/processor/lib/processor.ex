defmodule Processor do
  use GenServer
  require Logger

  @moduledoc """
  A `Processor` reads data from input queues, processes that same data and forwards it to processed queues.
  """

  defp dharma_exchange, do: Application.fetch_env!(:processor, :rabbit_exchange)

  @doc """
  Convenience method for starting a `Processor`.
  """
  def start_link(_opts) do
    rules = Database.get_rules()

    GenServer.start_link(__MODULE__, %{rules: rules}, [{:name, __MODULE__}])
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
    AMQP.Exchange.declare(channel, dharma_exchange(), :topic)
    create_queue(channel, "raw_input", ["insert.raw.*"])
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
      AMQP.Queue.bind(channel, queue_name, dharma_exchange(), routing_key: x)
    end)
  end

  # Process the payload and send it to the correct topic.
  defp process_and_send(payload, meta, state) do
    info = Jason.decode!(payload)
    Logger.info("[#{meta.routing_key}] #{info["action_type"]}", label: "[x] Received")

    case Processor.RulesAction.to_action(info, state.rules) do
      {:abort, error_message} ->
        Logger.info(error_message)

      {:ok, action} ->
        action_json = Jason.encode!(action)
        send("insert.processed.actions", action_json, state.channel)
    end
  end

  # Sends a `message` in the exchange "dharma", in a certain channel, with a `topic`.
  @spec send(String.t(), any, AMQP.Channel.t()) :: :ok
  defp send(topic, message, channel) do
    AMQP.Basic.publish(channel, dharma_exchange(), topic, message)
  end

  @impl true
  def handle_info(_, state) do
    {:noreply, state}
  end

  @impl true
  def handle_cast(:reload, state) do
    Logger.info("Reloading rules on processor!")
    rules = Database.get_rules()
    {:noreply, Map.put(state, :rules, rules)}
  end
end
