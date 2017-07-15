defmodule CorsPlug.Mixfile do
  use Mix.Project

  def project do
    [
      app: :cors_plug,
      version: "1.4.0",
      elixir: ">= 1.0.0",
      deps: deps(),
      package: package(),
      description: description(),
      docs: [
        extras: ~W(README.md CHANGELOG.md)
      ]
    ]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [applications: [:logger]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type `mix help deps` for more examples and options
  defp deps do
    [
      {:plug, "> 0.14.0"},

      {:ex_doc, "~> 0.11", only: :dev},
      {:earmark, "~> 1.2", only: :dev},
    ]
  end

  defp description do
    """
    An elixir plug that adds CORS headers to requests and responds to
    preflight requests (OPTIONS)
    """
  end

  defp package do
    [
      files: ~w(lib mix.exs README.md LICENSE CHANGELOG.md),
      maintainers: ["Michael Schaefermeyer"],
      licenses: ["Apache 2.0"],
      links: %{
        "Github" => "http://github.com/mschae/cors_plug",
        "Docs"   => "http://hexdocs.pm/cors_plug",
      }
    ]
  end
end
