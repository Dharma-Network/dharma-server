defmodule Database.Operations do
  @moduledoc """
  Module that contains all database operations we provide.
  """
  use Tesla

  defp db_url, do: Application.fetch_env!(:database, :url_db)
  defp db_name, do: Application.fetch_env!(:database, :name_db)
  defp mango_query_url, do: db_name() <> "/_find"
  defp changes_feed_url, do: db_name() <> "/_changes"

  plug(Tesla.Middleware.BaseUrl, db_url())
  plug(Tesla.Middleware.JSON)

  adapter(Tesla.Adapter.Finch, name: FinchAdapter)

  # Fetches the github sources from the database.
  def get_github_sources() do
    body = %{selector: %{project_type: %{"$eq": "github"}}, fields: ["list_of_urls"]}
    {:ok, resp} = post_with_retry(db_name() <> "/_find", body)

    case resp.body["docs"] do
      nil ->
        {:error, "No docs found"}

      docs ->
        docs
        |> Enum.flat_map(fn doc ->
          Enum.map(doc["list_of_urls"], fn url ->
            [_, owner, repo] = Regex.run(~r/.*\/(.*)\/(.*)$/, url)
            {{owner, repo}, ""}
          end)
        end)
        |> Enum.into(%{}, & &1)
    end
  end

  # Fetches the rules from the database.
  def get_rules() do
    body = %{
      selector: %{type: %{"$eq": "action_rules"}},
      fields: ["action_type", "rule_specific_details"]
    }

    {:ok, resp} = post_with_retry(mango_query_url(), body)

    resp.body["docs"]
    |> Enum.map(fn rule ->
      {rule["action_type"], rule["rule_specific_details"]}
    end)
    |> Enum.into(%{}, & &1)
  end

  # If the post fails then refresh the authentication and try again.
  def post_with_retry(path, body, query \\ []) do
    {:ok, resp} = post(client(), path, body, query: query)

    case resp.status do
      401 ->
        Database.Auth.refresh_auth()
        post_with_retry(path, body)

      _ ->
        {:ok, resp}
    end
  end

  # Returns the changes since the provided point, giving back the last_seq and the ids of the documents introduced.
  def fetch_changes do
    query = [feed: "longpoll", since: "now", heartbeat: 1000, filter: "_selector"]

    body = %{
      selector: %{type: %{"$eq": "action_rules"}}
    }

    {:ok, changes_resp} = post_with_retry(changes_feed_url(), body, query)

    ids =
      changes_resp.body["results"]
      |> Enum.map(fn change -> %{id: change["id"]} end)

    {:ok, resp} = post_to_db("_bulk_get", %{docs: ids})

    resp.body["results"]
  end

  # If the get fails then refresh the authentication and try again.
  defp get_with_retry(path, query \\ []) do
    {:ok, resp} = get(client(), path, query: query)

    case resp.status do
      401 ->
        Database.Auth.refresh_auth()
        get_with_retry(path, query)

      _ ->
        {:ok, resp}
    end
  end

  # Builds the headers for the requests.
  defp client do
    middleware = [
      {Tesla.Middleware.Headers, [{"Authorization", "Bearer " <> Database.Auth.get_auth()}]}
    ]

    Tesla.client(middleware)
  end

  # Posts a document with the given body
  # TO-DO: Don't rely on couchdb UUID
  def post_to_db(path \\ "", body) do
    post_with_retry("/" <> db_name() <> "/" <> path, body)
  end
end
