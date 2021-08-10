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

  alias Tentacat.Pulls.Files

  @default_extract_rate 5
  @source "github"

  defp dharma_exchange, do: Application.fetch_env!(:extractor, :rabbit_exchange)

  @doc """
  Convenience method for startup.
  """
  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(_opts) do
    sources =
      case Database.get_github_sources() do
        {:error, error_msg} ->
          Logger.critical(error_msg)
          []

        sources ->
          sources
      end

    GenServer.start_link(__MODULE__, %{source: sources}, [
      {:name, __MODULE__}
    ])
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
  def init(state) do
    new_state = start_connection(state)
    github_token = Application.get_env(:extractor, :github_token)
    client = Tentacat.Client.new(%{access_token: github_token})
    new_state = timer(Map.put(new_state, :client, client))
    {:ok, new_state}
  end

  defp fetch(state) do
    # For each individual fetch, accumulate the data provided and store the new etag that github sends back.
    {new_sources, data} =
      Enum.reduce(state.source, {%{}, []}, fn {{owner, repo}, etag}, acc = {map, list} ->
        case fetch(state, owner, repo, etag) do
          {new_etag, value} ->
            {Map.put(map, {owner, repo}, new_etag), [value | list]}

          nil ->
            acc
        end
      end)

    {Map.put(state, :source, new_sources), data}
  end

  # Fetches recent pulls.
  defp fetch(state, owner, repo, etag) do
    # Set a extra header to contain the etag header (only if it's not empty)
    Logger.info("#{owner} #{repo}", label: "fetching from ")
    Application.put_env(:tentacat, :extra_headers, [{"If-None-Match", "#{etag}"}])

    case efficient_pulling(state.client, owner, repo, state.date) do
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
  defp efficient_pulling(client, owner, repo, from) do
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
          |> Enum.map(fn pull -> extract_relevant_data(pull, client, owner, repo) end)

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
  def extract_relevant_data(pull, client, owner, repo) do
    {_status, files, _resp} = Files.list(client, owner, repo, pull["number"])
    {_status, reviews, _resp} = Reviews.list(client, owner, repo, pull["number"])
    {_status, commits, _resp} = Commits.list(client, owner, repo, pull["number"])

    %{
      owner: owner,
      repo: repo,
      action_type: "pull_request",
      pull: pull,
      reviews: reviews,
      files: files,
      commits: commits
    }

    # Enum.map(files, fn file ->
    # %{filename: file["filename"], additions: file["additions"], status: file["status"]}
    # end)
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
  defp start_connection(state) do
    url = Application.fetch_env!(:extractor, :rabbit_url)
    {:ok, connection} = AMQP.Connection.open(url)
    {:ok, channel} = AMQP.Channel.open(connection)
    AMQP.Exchange.declare(channel, dharma_exchange(), :topic)
    Map.merge(state, %{connection: connection, channel: channel})
  end

  # Publishes a message to an Exchange.
  @spec send(String.t(), String.t(), AMQP.Channel.t()) :: :ok
  defp send(message, source, channel) do
    topic = "insert.raw." <> source
    AMQP.Basic.publish(channel, dharma_exchange(), topic, message, persistent: true)
    Logger.info("[#{topic}] #{message}", label: "[x] Sent")
  end

  # Close RabbitMQ connection.
  @spec close_connection(AMQP.Connection.t()) :: :ok | {:error, any()}
  defp close_connection(connection) do
    AMQP.Connection.close(connection)
  end
end
