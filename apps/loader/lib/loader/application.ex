defmodule Loader.Application do
  @moduledoc false

  use Application
  use Tesla

  plug(Tesla.Middleware.Logger)

  @url Application.fetch_env!(:loader, :url_db)

  @impl true
  def start(_type, _args) do
    Finch.start_link(name: MyFinch)
    client =
      client()
      |> get_cookie()
      |> client()

    children = [
      {Loader, client}
    ]

    opts = [strategy: :one_for_one, name: Loader.Supervisor]
    Supervisor.start_link(children, opts)
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
