defmodule FakeServer.Mixfile do
  use Mix.Project

  def project do
    [
      app: :fake_server,
      version: "3.0.0",
      elixir: "~> 1.18",
      description: description(),
      package: package(),
      aliases: aliases(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        "coveralls.cobertura": :test
      ],
      elixirc_paths: elixirc_paths(Mix.env()),
      docs: [
        groups_for_functions: [
          Macros: &(&1[:section] == :macro)
        ]
      ],
      deps: deps()
    ]
  end

  def application do
    [extra_applications: [:logger, :cowboy], mod: {FakeServer.Application, []}]
  end

  defp deps do
    [
      {:cowboy, "~> 2.13"},
      {:faker, "~> 0.19.0-alpha.1", only: :test},
      {:ex_doc, "~> 0.35", only: :dev},
      {:req, "~> 0.5.0 or ~> 0.6.0"},
      {:excoveralls, "~> 0.18", only: :test},
      {:mix_test_watch, "~> 1.2", only: [:dev, :test]}
    ]
  end

  defp description do
    """
    With FakeServer you can create individual HTTP servers for each test case, allowing external requests to be tested without the need for mocks.
    """
  end

  defp package do
    [
      name: :fake_server,
      maintainers: ["Bernardo Lins"],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => "https://github.com/bernardolins/fake_server"}
    ]
  end

  defp aliases do
    [test: "test --no-start"]
  end

  defp elixirc_paths(:test), do: ["lib", "test/integration/support"]
  defp elixirc_paths(_), do: ["lib"]
end
