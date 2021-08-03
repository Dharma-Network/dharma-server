defmodule Extractor.Application do
  @moduledoc false

  use Application
  use Tesla

  @url Application.fetch_env!(:extractor, :url_db)
  @name_db Application.fetch_env!(:extractor, :name_db)

  @impl true
  def start(_type, _args) do
    Finch.start_link(name: MyFinch)
    Logger.remove_backend(:console)
    opts = [strategy: :one_for_one, name: Extractor.Supervisor]
    github_sources = get_github_sources()
    children = [
      {Extractor.Github, github_sources}
      # {Extractor.Trello, client}
    ]

    Supervisor.start_link(children, opts)
  end

  defp get_github_sources() do
    client =
      client()
      |> get_cookie()
      |> client()

    body = %{selector: %{project_type: %{"$eq": "github"}}, fields: ["list_of_urls"]}
    {:ok, resp} = post(client, @url <> "/" <> @name_db <> "/_find", body)

    resp.body["docs"]
    |> Enum.flat_map(fn doc ->
      Enum.map(doc["list_of_urls"], fn url ->
        [_, owner, repo] = Regex.run(~r/.*\/(.*)\/(.*)$/, url)
        {{owner, repo}, ""}
      end)
    end)
    |> Enum.into(%{}, &(&1))
  end

  def client(cookie \\ "")

  def client(cookie) when cookie == "" do
    Tesla.client(
      [
        {Tesla.Middleware.BaseUrl, @url},
        Tesla.Middleware.JSON
      ],
      {Tesla.Adapter.Finch, name: MyFinch}
    )
  end

  def client(cookie) do
    Tesla.client(
      [
        {Tesla.Middleware.BaseUrl, @url},
        {Tesla.Middleware.Headers, [{"cookie", cookie}]},
        Tesla.Middleware.JSON
      ],
      {Tesla.Adapter.Finch, name: MyFinch}
    )
  end

  defp get_cookie(client) do
    user_name = Application.fetch_env!(:loader, :user_db)
    user_password = Application.fetch_env!(:loader, :password_db)
    body = %{"name" => user_name, "password" => user_password}
    {:ok, response} = post(client, "_session", body)

    Tesla.get_header(response, "set-cookie")
  end
end
