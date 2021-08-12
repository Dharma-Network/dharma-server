defmodule DharmaServer.MixProject do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      version: "0.1.0",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: [
        dharma_server: [
          applications: [
            database: :permanent,
            extractor: :permanent,
            loader: :permanent,
            processor: :permanent
          ]
        ]
      ],
      # Docs
      name: "Dharma Server",
      source_url: "https://github.com/Dharma-Network/dharma-server",
      docs: [
        main: "api-reference"
      ]
    ]
  end

  # Dependencies listed here are available only for this
  # project and cannot be accessed from applications inside
  # the apps folder.
  #
  # Run "mix help deps" for examples and options.
  defp deps do
    [
      {:amqp, "~> 1.0"},

      # ---- Test and Dev
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.24", only: :dev, runtime: false}
    ]
  end
end
