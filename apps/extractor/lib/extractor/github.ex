defmodule Extractor.Github do
  @moduledoc """
  This is the `Connector` module.
  This module aims to receive raw data from
  external data sources and
  publish it to a RabbitMQ exchange.
  """

  @moduledoc since: "1.0.0"

  use GenServer
  require Logger

  alias Tentacat.Pulls.Commits
  alias Tentacat.Pulls.Files
  alias Tentacat.Pulls.Reviews

  @default_extract_rate 5
  @source "github"

  defp dharma_exchange, do: Application.fetch_env!(:extractor, :rabbit_exchange)

  @doc """
  Convenience method for startup.
  """
  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, [{:name, __MODULE__}])
  end

  # Fetch pull time.
  defp pull_time do
    rate = @source <> "_extract_rate"
    time = Application.get_env(:extractor, String.to_atom(rate), @default_extract_rate)
    time * 60 * 1000
  end

  @doc """
  Callbacks for GenServer.Behaviour.
  """
  @impl true
  def init(_state) do
    state = build_state()
    new_state = timer(state)
    {:ok, new_state}
  end

  defp build_state do
    sources =
      case Database.get_github_sources() do
        {:error, error_msg} ->
          Logger.critical(error_msg)
          []

        {:ok, sources} ->
          sources
      end

    conn = Extractor.Github.start_connection()
    github_token = Application.get_env(:extractor, :github_token)
    client = Tentacat.Client.new(%{access_token: github_token})
    Map.merge(%{client: client, source: sources}, conn)
  end

  @doc """
  Calls the :fetch_from endpoint with the provided date.
  Date format: YY-MM-DD HH:MM:SS
  """
  @spec fetch_from(String.t()) :: :ok
  def fetch_from(date) do
    case NaiveDateTime.from_iso8601(date) do
      {:ok, ndt} ->
        GenServer.cast(__MODULE__, {:fetch_from, ndt})

      {:error, reason} ->
        Logger.info("Failed to convert #{date} because #{reason}.")
    end
  end

  defp fetch(state) do
    # For each individual fetch, accumulate the data provided and store the new etag that github sends back.
    {new_sources, data} =
      Enum.reduce(state.source, {%{}, []}, fn {{owner, repo, proj_id}, etag}, {map, list} ->
        case fetch(state, owner, repo, proj_id, etag) do
          {new_etag, value} ->
            {Map.put(map, {owner, repo}, new_etag), [value | list]}

          nil ->
            {Map.put(map, {owner, repo}, etag), list}
        end
      end)

    {Map.put(state, :source, new_sources), Enum.concat(data)}
  end

  # Fetches recent pulls.
  defp fetch(state, owner, repo, proj_id, etag) do
    # Set a extra header to contain the etag header (only if it's not empty)
    Logger.info("#{owner} #{repo}", label: "fetching from ")
    Application.put_env(:tentacat, :extra_headers, [{"If-None-Match", "#{etag}"}])

    case efficient_pulling(state.client, owner, repo, state.date, proj_id) do
      {[], _resp} ->
        nil

      {pulls, resp} ->
        new_etag = retrieve_etag(resp)
        {new_etag, pulls}

      nil ->
        nil
    end
  end

  # Obtain pulls sorted by most recent closed order.
  # We use take_while to avoid going through any pull that's before from.
  defp efficient_pulling(client, owner, repo, from, proj_id) do
    filters = %{state: "closed", sort: "updated", direction: "desc"}

    case Tentacat.Pulls.filter(client, owner, repo, filters) do
      # Regular response from github api
      {200, pulls, resp} ->
        value =
          pulls
          |> Enum.take_while(fn pull ->
            {:ok, dt} = NaiveDateTime.from_iso8601(pull["closed_at"])
            valid_time?(dt, from)
          end)
          |> Enum.filter(&is_merged?(&1, client, owner, repo))
          |> Enum.map(fn pull -> extract_relevant_data(pull, client, owner, repo, proj_id) end)

        {value, resp}

      # Etag used successfully
      {304, nil, _resp} ->
        nil
    end
  end

  # Checks if a datetime is after the provided one.
  defp valid_time?(dt, from) do
    NaiveDateTime.compare(dt, from) == :gt
  end

  # Filters relevant data from a pull request.
  def extract_relevant_data(pull, client, owner, repo, proj_id) do
    {_status, files, _resp} = Files.list(client, owner, repo, pull["number"])
    {_status, reviews, _resp} = Reviews.list(client, owner, repo, pull["number"])
    {_status, commits, _resp} = Commits.list(client, owner, repo, pull["number"])

    %{
      proj_id: proj_id,
      owner: owner,
      repo: repo,
      action_type: "pull_request",
      pull: pull,
      reviews: reviews,
      files: files,
      commits: commits
    }
  end

  # Retrieves the ETag from a response, will be needed when we implement conditional requests.
  defp retrieve_etag(resp) do
    resp.headers
    |> Enum.filter(&match?({"ETag", _}, &1))
    |> hd
    |> elem(1)
  end

  defp is_merged?(pull, client, owner, repo) do
    merged_info = Tentacat.Pulls.has_been_merged(client, owner, repo, pull["number"])

    # Confirms that it was merged (not including closed PR's this way)
    match?({204, _, _}, merged_info)
  end

  @doc """
  Fetch pulls every `EXTRACT_RATE` and send them to RabbitMQ queue.
  """
  @impl true
  def handle_info(:pull_data, state) do
    new_state =
      case fetch(state) do
        {_, []} ->
          state

        {new_state, data} ->
          data
          |> Enum.each(fn pull_data ->
            pull_data
            |> Jason.encode!()
            |> send(@source, state.channel)
          end)

          new_state
      end

    timer(new_state)
    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:fetch_from, date}, state) do
    hacked = Map.put(state, :date, date)
    data = elem(fetch(hacked), 1)

    if data != [] do
      Enum.each(data, fn pull_data ->
        pull_data
        |> Jason.encode!()
        |> send(@source, state.channel)

        info = pull_data.pull
        Logger.info(info["url"] <> ": " <> info["title"])
      end)
    end

    {:noreply, state}
  end

  # Update DateTime and schedule pull.
  defp timer(state) do
    date = DateTime.utc_now()
    Process.send_after(self(), :pull_data, pull_time())
    Map.put(state, :date, date)
  end

  @doc """
  Closes the connection with RabbitMQ on exit.
  """
  @impl true
  def terminate(_reason, state) do
    close_connection(state.connection)
  end

  # Start a connection with RabbitMQ and declare an exchange.
  def start_connection do
    url = Application.fetch_env!(:extractor, :rabbit_url)
    {:ok, connection} = AMQP.Connection.open(url)
    {:ok, channel} = AMQP.Channel.open(connection)
    AMQP.Exchange.declare(channel, dharma_exchange(), :topic)
    %{connection: connection, channel: channel}
  end

  # Publishes a message to an Exchange.
  @spec send(String.t(), String.t(), AMQP.Channel.t()) :: :ok
  defp send(message, source, channel) do
    topic = "insert.raw." <> source
    AMQP.Basic.publish(channel, dharma_exchange(), topic, message, persistent: true)
  end

  # Close RabbitMQ connection.
  @spec close_connection(AMQP.Connection.t()) :: :ok | {:error, any()}
  defp close_connection(connection) do
    AMQP.Connection.close(connection)
  end
end
