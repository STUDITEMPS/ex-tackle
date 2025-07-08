defmodule Tackle.Mixfile do
  use Mix.Project

  def project do
    [
      app: :tackle,
      version: "1.0.0",
      elixir: "~> 1.15",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: preferred_cli_env(),
      elixirc_options: [warnings_as_errors: false],
      elixirc_paths: elixirc_paths(Mix.env()),
      test_paths: ["test"]
    ]
  end

  def application do
    [extra_applications: [:logger, :amqp, :public_key], mod: {Tackle, []}]
  end

  defp deps do
    [
      {:amqp, "~> 4.0"},
      {:excoveralls, "~> 0.17", only: :test},
      {:tesla, "~> 1.9", only: :test},
      {:jason, "~> 1.4", only: :test},
      {:mint, "~> 1.0", only: :test},
      {:castore, "~> 1.0", only: :test}
    ]
  end

  defp preferred_cli_env do
    [
      coveralls: :test,
      "coveralls.detail": :test,
      "coveralls.post": :test,
      "coveralls.html": :test
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
