defmodule Database.Auth do
  use Agent
  use Tesla
  use Joken.Config

  @url Application.fetch_env!(:database, :url_db)
  @exp_claim_type 60 * 60 * 24 * 14

  plug(Tesla.Middleware.BaseUrl, @url)
  plug(Tesla.Middleware.JSON)

  adapter(Tesla.Adapter.Finch, name: FinchAdapter)

  @sign_alg "HS256"
  # Convenience function to launch the auth agent.
  def start_link(_opts) do
    Agent.start_link(fn -> retrieve_jwt() end, name: __MODULE__)
  end

  # Configures the generation of JWT tokens.
  defp token_config() do
    default_claims(
      skip: [:iss, :aud, :jti, :adu, :nbf, :iat],
      default_exp: @exp_claim_type
    )
    |> add_claim("sub", fn -> "admin" end, &(&1 == "admin"))
  end

  # Builds a new JWT token.
  defp retrieve_jwt() do
    signer = Joken.Signer.create(@sign_alg, "password")
    {:ok, token, _claims} = generate_and_sign(%{}, signer) |> IO.inspect()
    Joken.expand(token) |> IO.inspect()
    IO.puts("Retrieve jwt")
    token
  end

  # Returns the JWT token stored by the agent.
  def get_jwt do
    Agent.get(__MODULE__, & &1)
  end

  # Forces a new JWT token to be created, replacing the previous one that the agent contained.
  def refresh_jwt() do
    Agent.update(__MODULE__, fn _ -> retrieve_jwt() end)
  end
end
