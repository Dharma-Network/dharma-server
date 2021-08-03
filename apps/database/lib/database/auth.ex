defmodule Database.Auth do
  use Agent
  use Tesla

  @url Application.fetch_env!(:database, :url_db)

  plug(Tesla.Middleware.BaseUrl, @url)
  plug(Tesla.Middleware.JSON)

  adapter(Tesla.Adapter.Finch, name: FinchAdapter)

  def start_link(_opts) do
    Agent.start_link(fn -> retrieve_cookie() end, name: __MODULE__)
  end

  def get_cookie do
    Agent.get(__MODULE__, & &1)
  end

  def refresh_cookie() do
    Agent.update(__MODULE__, fn _ -> retrieve_cookie() end)
  end

  defp retrieve_cookie() do
    user_name = Application.fetch_env!(:database, :user_db)
    user_password = Application.fetch_env!(:database, :password_db)
    body = %{"name" => user_name, "password" => user_password}
    {:ok, response} = post("_session", body)

    Tesla.get_header(response, "set-cookie")
  end
end
