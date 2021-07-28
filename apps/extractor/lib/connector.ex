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
    #simulate_external_message(new_state)
    d1 = ~U[2020-06-27 13:21:50Z]
    d2 = ~U[2022-08-27 13:21:50Z]
    user = "PedroSilva9"
    fetch_pulls(user, {d1, d2})
    {:ok, new_state}
  end

  # Fetches pulls from a user in a timewindow
  defp fetch_pulls(user, tw) do
    owner = "Dharma-Network"
    repo = "dharma-server"
    filters = %{state: "closed"}
    github_token = Application.get_env(:extractor, :github_token)
    client = Tentacat.Client.new(%{access_token: github_token})
    # Set a extra header to contain the etag header
    # TODO: Understand why this fails despite working on cmd
    #Application.put_env(:tentacat, :extra_headers, [{"If-None-Match", "92b6cbeda07e5faaebb4b58bc30425f994661c54a1bf23e2af1f548f936b3651"}])

    {_status, pulls, resp} = Tentacat.Pulls.filter(client, owner, repo, filters)
    # Probably should be cached somewhere to be included in requests later
    _etag = retrieve_etag(resp) |> IO.inspect(label: "ETAG: ")
    pulls
    |> Enum.filter(fn pull ->
      validate_pull(pull, user, tw, client, owner, repo)
    end)
    |> length |> IO.inspect
  end

  # Retrieves the ETag from a response, will be needed when we implement conditional requests
  defp retrieve_etag(resp) do
    Enum.filter(resp.headers, &match?({"ETag", _}, &1)) |> hd
  end

  # Center validation in a function
  defp validate_pull(pull, user, {from, to}, client, owner, repo) do
    {:ok, dt, 0} = DateTime.from_iso8601(pull["created_at"])
    merged_info = Tentacat.Pulls.has_been_merged(client, owner, repo, pull["number"])

    # Matching user
    pull["user"]["login"] == user &&
    # Between the accepted time window
    is_between?(dt, from, to) &&
    # Confirms that it was merged (not including closed PR's this way)
    match?({204, _, _}, merged_info)
  end

  defp is_between?(current, from, to) do
    DateTime.compare(current,from) == :gt && DateTime.compare(current, to) == :lt
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
