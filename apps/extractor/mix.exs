defmodule Extractor.MixProject do
  use Mix.Project

  def project do
    [
      app: :extractor,
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
      extra_applications: [:lager, :logger, :amqp, :jason, :database],
      mod: {Extractor.Application, []},
      applications: [:amqp, :tentacat]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jason, "~> 1.2"},
      {:amqp, "~> 1.0"},
      {:tentacat, "~> 1.0"},
      {:database, in_umbrella: true}
    ]
  end
end
