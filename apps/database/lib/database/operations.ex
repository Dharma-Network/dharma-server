defmodule Database.Operations do
  use Tesla

  @url Application.fetch_env!(:database, :url_db)
  @name_db Application.fetch_env!(:database, :name_db)

  plug(Tesla.Middleware.BaseUrl, @url)
  plug(Tesla.Middleware.JSON)

  adapter(Tesla.Adapter.Finch, name: FinchAdapter)

  def get_github_sources() do
    body = %{selector: %{project_type: %{"$eq": "github"}}, fields: ["list_of_urls"]}
    {:ok, resp} = post_with_retry(@name_db <> "/_find", body)

    resp.body["docs"]
    |> Enum.flat_map(fn doc ->
      Enum.map(doc["list_of_urls"], fn url ->
        [_, owner, repo] = Regex.run(~r/.*\/(.*)\/(.*)$/, url)
        {{owner, repo}, ""}
      end)
    end)
    |> Enum.into(%{}, & &1)
  end

  defp post_with_retry(path, body) do
    {:ok, resp} = post(client(), path, body)

    case resp.status do
      401 ->
        Database.Auth.refresh_auth()
        post_with_retry(path, body)

      _ ->
        {:ok, resp}
    end
  end

  defp client do
    middleware = [
      {Tesla.Middleware.Headers, [{"Authorization", "Bearer " <> Database.Auth.get_auth()}]}
    ]

    Tesla.client(middleware)
  end

  # TODO: Don't rely on couchdb UUID
  def post(body) do
    post_with_retry("/" <> @name_db, body)
  end
end
