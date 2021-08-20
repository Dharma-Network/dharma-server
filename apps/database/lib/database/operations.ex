defmodule Database.Operations do
  @moduledoc """
  Module that contains all database operations we provide.
  """
  use Tesla
  require Logger

  defp db_url, do: Application.fetch_env!(:database, :url_db)
  defp db_name, do: Application.fetch_env!(:database, :name_db)
  defp mango_query_url, do: db_name() <> "/_find"
  defp changes_feed_url, do: db_name() <> "/_changes"

  plug(Tesla.Middleware.BaseUrl, db_url())
  plug(Tesla.Middleware.JSON)

  adapter(Tesla.Adapter.Finch, name: FinchAdapter)

  # Fetches the github sources from the database.
  def get_github_sources do
    query = %{
      selector: %{project_type: %{"$eq": "github"}, type: %{"$eq": "project"}},
      fields: ["_id", "list_of_urls"]
    }

    case post_with_retry(db_name() <> "/_find", query) do
      {:ok, resp} ->
        case resp.body["docs"] do
          nil ->
            Logger.critical("No docs found")
            {:error, %{}}

          docs ->
            {:ok, extract_sources(docs)}
        end

      {:error, _reason} ->
        Logger.critical("No docs found")
        {:error, %{}}
    end
  end

  def find_action(external_id) do
    query = %{
      selector: %{type: %{"$eq": "action"}, external_id: %{"$eq": external_id}},
      fields: ["_id"]
    }

    case post_with_retry(db_name() <> "/_find", query) do
      {:ok, resp} ->
        case resp.body["docs"] do
          nil ->
            false

          [] ->
            false

          _docs ->
            true
        end

      {:error, _reason} ->
        false
    end
  end

  defp extract_sources(docs) do
    docs
    |> Enum.flat_map(fn doc ->
      Enum.map(doc["list_of_urls"], fn url ->
        [_, owner, repo] = Regex.run(~r/.*\/(.*)\/(.*)$/, url)
        {{owner, repo, doc["_id"]}, ""}
      end)
    end)
    |> Enum.into(%{}, & &1)
  end

  # Fetches the rules from the database.
  def get_rules do
    query = %{
      selector: %{type: %{"$eq": "action_rules"}},
      fields: ["action_type", "rule_specific_details"]
    }

    case post_with_retry(mango_query_url(), query) do
      {:ok, resp} ->
        case resp.body["docs"] do
          nil ->
            %{}

          res ->
            extract_rules(res)
        end

      {:error, _reason} ->
        Logger.critical("Error while trying to execute post_with_retry")
        %{}
    end
  end

  defp extract_rules(res) do
    res
    |> Enum.map(fn rule ->
      {rule["action_type"], rule["rule_specific_details"]}
    end)
    |> Enum.into(%{}, & &1)
  end

  # If the post fails then refresh the authentication and try again.
  defp post_with_retry(path, body, query \\ []) do
    case post(client(), path, body, query: query) do
      {:ok, resp} ->
        case resp.status do
          401 ->
            Database.Auth.refresh_auth()
            post_with_retry(path, body)

          _ ->
            {:ok, resp}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Builds the headers for the requests.
  defp client do
    middleware = [
      {Tesla.Middleware.Headers, [{"Authorization", "Bearer " <> Database.Auth.get_auth()}]}
    ]

    Tesla.client(middleware)
  end

  # Returns the changes since the provided point, giving back the last_seq and the ids of the documents introduced.
  def fetch_changes do
    query = [
      feed: "longpoll",
      since: "now",
      heartbeat: 1000,
      filter: "_selector",
      include_docs: true
    ]

    body = %{
      selector: %{type: %{"$eq": "action_rules"}}
    }

    case post_with_retry(changes_feed_url(), body, query) do
      {:ok, resp} ->
        case resp.body["results"] do
          nil ->
            []

          res ->
            res
        end

      {:error, reason} ->
        Logger.critical("Error in fetch_changes with the
             following reason: " <> reason)
        []
    end
  end

  def validate_user?(user_nickname, project_id) do
    query = %{
      selector: %{
        "$and": [
          %{type: %{"$eq": "user"}},
          %{nickname: %{"$eq": user_nickname}},
          %{list_of_projects: %{"$elemMatch": %{"$eq": project_id}}}
        ]
      }
    }

    resp = post_with_retry(mango_query_url(), query)

    case resp do
      {:ok, res} ->
        case res.body["docs"] do
          [] -> false
          _ -> true
        end

      {:error, _} ->
        false
    end
  end

  # Posts a document with the given body
  # TO-DO: Don't rely on couchdb UUID
  def post_to_db(path \\ "", body) do
    case post_with_retry("/" <> db_name() <> "/" <> path, body) do
      {:ok, _resp} ->
        :ok

      {:error, reason} ->
        Logger.critical("Error in post_to_db with the
             following reason: " <> reason)
        :fail
    end
  end

  def put_to_db(endpoint, body, query \\ []) do
    put(client(), endpoint, body, query: query)
  end

  def get_from_db(path, query \\ []) do
    get(client(), "/" <> db_name() <> "/" <> path, query: query)
  end
end
