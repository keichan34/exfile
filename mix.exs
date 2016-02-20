defmodule Exfile.Mixfile do
  use Mix.Project

  def project do
    [
      app: :exfile,
      version: "0.1.2",
      elixir: "~> 1.2.0",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps,
      elixirc_paths: elixirc_paths(Mix.env),
      source_url: "https://github.com/keichan34/exfile",
      docs: [
        extras: ["README.md"]
      ],
      package: package,
      description: description,
      dialyzer: [
        plt_file: ".local.plt",
        plt_add_apps: [
          :plug
        ]
      ]
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [
      mod: {Exfile, []},
      applications: [
        :logger,
        :plug,
        :crypto
      ]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  defp deps do
    [
      {:plug, "~> 1.0.0"},
      {:ecto, "~> 1.0"},
      {:phoenix_html, "~> 2.3"},
      {:poison, "~> 1.5", only: :test},
      {:earmark, "~> 0.1", only: :dev},
      {:ex_doc, "~> 0.11", only: :dev}
    ]
  end

  defp package do
    [
      files: ["lib", "priv", "mix.exs", "README*", "LICENSE*"],
      maintainers: ["Keitaroh Kobayashi"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/keichan34/exfile",
        "Docs" => "http://hexdocs.pm/exfile/readme.html"
      }
    ]
  end

  defp description do
    """
    File upload handling in Elixir and Plug. Supports pluggable processors and
    storage backends.
    """
  end
end
