defmodule CorsPlug.Mixfile do
  use Mix.Project

  @source_url "https://github.com/mschae/cors_plug"
  @version "2.0.3"

  def project do
    [
      app: :cors_plug,
      version: @version,
      elixir: "~> 1.9",
      deps: deps(),
      package: package(),
      description: description(),
      docs: [
        extras: ~W(CHANGELOG.md README.md),
        main: "readme",
        api_reference: false,
        source_url: @source_url,
        source_ref: "v#{@version}"
      ]
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:plug, "~> 1.8"},
      {:ex_doc, "~> 0.23.0", only: :dev, runtime: false},
      {:earmark, "~> 1.4", only: :dev, runtime: false},
      {:mix_test_watch, "~> 1.0", only: :test}
    ]
  end

  defp description do
    """
    An Elixir Plug that adds Cross-Origin Resource Sharing (CORS) headers to
    requests and responds to preflight requests (OPTIONS).
    """
  end

  defp package do
    [
      files: ~w(lib mix.exs README.md LICENSE CHANGELOG.md),
      maintainers: ["Michael Schaefermeyer"],
      licenses: ["Apache-2.0"],
      links: %{
        "Changelog" => "https://hexdocs.pm/cors_plug/changelog.html",
        "Github" => @source_url
      }
    ]
  end
end
