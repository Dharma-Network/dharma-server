defmodule Database.Auth do
  @moduledoc """
  Module that deals with authentication and provides it seamlessly.
  """

  use Agent
  use Joken.Config

  defp jwt_secret, do: Application.fetch_env!(:database, :jwt_secret)

  @sign_alg "HS256"
  @exp_claim_time 14
  @sub_user "admin"

  # Convenience function to launch the auth agent.
  def start_link(_opts) do
    Agent.start_link(fn -> retrieve_auth() end, name: __MODULE__)
  end

  # Configures the generation of JWT tokens.
  defp token_config do
    default_claims(
      skip: [:iss, :aud, :jti, :adu, :nbf],
      default_exp: @exp_claim_time * 60 * 60 * 24
    )
    |> add_claim("sub", fn -> @sub_user end, &(&1 == @sub_user))
  end

  # Builds a new JWT token.
  defp retrieve_auth do
    signer = Joken.Signer.create(@sign_alg, jwt_secret())
    {:ok, token, _claims} = generate_and_sign(%{}, signer)
    token
  end

  # Returns the JWT token stored by the agent.
  def get_auth do
    Agent.get(__MODULE__, fn token -> token end)
  end

  # Forces a new JWT token to be created, replacing the previous one that the agent contained.
  def refresh_auth do
    Agent.update(__MODULE__, fn _ -> retrieve_auth() end)
  end
end
