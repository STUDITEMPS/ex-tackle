defmodule Tackle.Mixfile do
  use Mix.Project

  def project do
    [
      app: :tackle,
      version: "0.2.0",
      elixir: "~> 1.6",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: preferred_cli_env()
    ]
  end

  def application do
    [applications: [:lager, :logger, :amqp], mod: {Tackle, []}]
  end

  defp deps do
    [
      {:amqp, "~> 1.4.1"},
      {:ex_spec, "~> 2.0", only: :test},
      {:excoveralls, "~> 0.10", only: :test},
      {:tesla, "~> 1.4.1", only: :test}
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
