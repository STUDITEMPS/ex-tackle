defmodule Tackle.Mixfile do
  use Mix.Project

  def project do
    [
      app: :tackle,
      version: "1.0.0",
      elixir: "~> 1.6",
      elixirc_paths: elixirc_paths(Mix.env()),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_paths: ["test"],
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: preferred_cli_env()
    ]
  end

  def application do
    [applications: [:logger, :amqp, :public_key, :inets], mod: {Tackle, []}]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:amqp, "~> 3.2"},
      {:ex_spec, "~> 2.0", only: [:test, :dev]},
      {:excoveralls, "~> 0.10", only: [:test, :dev]},
      {:tesla, "~> 1.4.1", only: [:test, :dev]}
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
end
