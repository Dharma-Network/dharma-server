defmodule Database.Auth do
  use Agent
  use Tesla
  use Joken.Config

  @url Application.fetch_env!(:database, :url_db)

  plug(Tesla.Middleware.BaseUrl, @url)
  plug(Tesla.Middleware.JSON)

  adapter(Tesla.Adapter.Finch, name: FinchAdapter)

  @sign_alg "HS256"
  def start_link(_opts) do
    Agent.start_link(fn -> retrieve_jwt() end, name: __MODULE__)
  end

  # Set exp claim.
  def token_config() do
    default_claims(
      skip: [:iss, :aud, :jti, :adu, :nbf, :iat],
      default_exp: 3
    )
    |> add_claim("sub", fn -> "admin" end, &(&1 == "admin"))
  end

  def retrieve_jwt() do
    signer = Joken.Signer.create(@sign_alg, "password")
    {:ok, token, _claims} = generate_and_sign(%{}, signer) |> IO.inspect()
    Joken.expand(token) |> IO.inspect()
    IO.puts("Retrieve jwt")
    token
  end

  def get_jwt do
    Agent.get(__MODULE__, & &1)
  end

  def refresh_jwt() do
    Agent.update(__MODULE__, fn _ -> retrieve_jwt() end)
  end
end
