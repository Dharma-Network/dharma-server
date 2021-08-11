defmodule Mix.Tasks.Replay do
  @moduledoc "Printed when the user requests `mix help echo`"
  @shortdoc "Echoes arguments"

  use Mix.Task
  require Logger

  @source "github"
  defp dharma_exchange, do: Application.fetch_env!(:extractor, :rabbit_exchange)

  # Publishes a message to an Exchange.
  @spec send(String.t(), String.t(), AMQP.Channel.t()) :: :ok
  defp send(message, source, channel) do
    topic = "insert.raw." <> source
    AMQP.Basic.publish(channel, dharma_exchange(), topic, message, persistent: true)
  end

  defp send_pull_data({state, pulls}) do
    pulls
    |> Enum.each(fn pull_data ->
      pull_data
      |> Jason.encode!()
      |> send(@source, state.channel)

      info = pull_data.pull
      Mix.shell().info(info["url"] <> ": " <> info["title"])
    end)
  end

  @impl Mix.Task
  def run(args) do
    # Start the necessary modules
    Mix.Task.run("app.start")

    case OptionParser.parse(args, strict: [since: :string]) do
      {[since: date], _, _} ->
        # Validate the format of the date
        case NaiveDateTime.from_iso8601(date) do
          {:ok, ndt} ->
            # Create a mock state and pull data using fetch/1.
            Extractor.Github.build_state()
            |> Map.put(:date, ndt)
            |> Extractor.Github.fetch()
            |> send_pull_data()

          {:error, error} ->
            Mix.shell().info(
              "Invalid --since argument provided, failed with reason #{error} for #{date}"
            )
        end

      _ ->
        Mix.shell().info("Invalid arguments, a --since is required!")
    end
  end
end
