defmodule Database.Operations do
  use Tesla

  @url Application.fetch_env!(:database, :url_db)
  @name_db Application.fetch_env!(:database, :name_db)

  plug(Tesla.Middleware.BaseUrl, @url)
  plug(Tesla.Middleware.JSON)
  adapter(Tesla.Adapter.Finch, name: FinchAdapter)

  def get_github_sources() do
    client = get_cookie() |> client()

    body = %{selector: %{project_type: %{"$eq": "github"}}, fields: ["list_of_urls"]}
    {:ok, resp} = post(client, @name_db <> "/_find", body)

    resp.body["docs"]
    |> Enum.flat_map(fn doc ->
      Enum.map(doc["list_of_urls"], fn url ->
        [_, owner, repo] = Regex.run(~r/.*\/(.*)\/(.*)$/, url)
        {{owner, repo}, ""}
      end)
    end)
    |> Enum.into(%{}, & &1)
  end

  defp client(cookie) do
    Tesla.client([
      {Tesla.Middleware.Headers, [{"cookie", cookie}]}
    ])
  end

  defp get_cookie() do
    user_name = Application.fetch_env!(:database, :user_db)
    user_password = Application.fetch_env!(:database, :password_db)
    body = %{"name" => user_name, "password" => user_password}
    {:ok, response} = post("_session", body)

    Tesla.get_header(response, "set-cookie")
  end

  # TODO: Don't rely on couchdb UUID
  def post(body) do
    post("/" <> @name_db, body)
  end

end
