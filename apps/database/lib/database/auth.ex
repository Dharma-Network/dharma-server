defmodule Database.Auth do
  use Agent
  use Tesla
  use Joken.Config

  @url Application.fetch_env!(:database, :url_db)
  @jwt_secret Application.fetch_env!(:database, :jwt_secret)
  @sign_alg "HS256"
  @exp_claim_time 14
  @sub_user "admin"

  plug(Tesla.Middleware.BaseUrl, @url)
  plug(Tesla.Middleware.JSON)

  adapter(Tesla.Adapter.Finch, name: FinchAdapter)

  def start_link(_opts) do
    Agent.start_link(fn -> retrieve_auth() end, name: __MODULE__)
  end

  # Set exp claim.
  defp token_config() do
    default_claims(
      skip: [:iss, :aud, :jti, :adu, :nbf, :iat],
      default_exp: @exp_claim_time * 60 * 60 * 24
    )
    |> add_claim("sub", fn -> @sub_user end, &(&1 == @sub_user))
  end

  defp retrieve_auth() do
    signer = Joken.Signer.create(@sign_alg, @jwt_secret)
    {:ok, token, _claims} = generate_and_sign(%{}, signer)
    Joken.expand(token)
    token
  end

  def get_auth do
    Agent.get(__MODULE__, & &1)
  end

  def refresh_auth() do
    Agent.update(__MODULE__, fn _ -> retrieve_auth() end)
  end
end
