defmodule Loader.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  use Tesla

  plug(Tesla.Middleware.Logger)

  @impl true
  def start(_type, _args) do
    Finch.start_link(name: MyFinch)
    client = client()
    cookie = get_cookie(client)
    client = client(cookie)

    children = [
      {Loader, client}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Loader.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def client(cookie \\ "")

  def client(cookie) when cookie == "" do
    base_url = Application.fetch_env!(:loader, :url)

    Tesla.client(
      [
        {Tesla.Middleware.BaseUrl, base_url},
        Tesla.Middleware.JSON
      ],
      {Tesla.Adapter.Finch, name: MyFinch}
    )
  end

  def client(cookie) do
    base_url = Application.fetch_env!(:loader, :url)

    Tesla.client(
      [
        {Tesla.Middleware.BaseUrl, base_url},
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

    cookie =
      hd(Enum.take(response.headers, -1))
      |> Kernel.elem(1)

    cookie
  end
end
