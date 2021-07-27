defmodule Loader.MixProject do
  use Mix.Project

  def project do
    [
      app: :loader,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      applications: [:amqp, :tesla, :jason, :finch],
      mod: {Loader.Application, []},
      env: [url: [], user_db: [], password_db: [], rabbit_url: [], rabbit_exchange: []]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:tesla, "~> 1.4"},
      {:finch, "~> 0.3"},
      {:jason, "~> 1.2"},
      {:amqp, "~> 1.0"}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
