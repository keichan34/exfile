defmodule Exfile.Mixfile do
  use Mix.Project

  def project do
    [
      app: :exfile,
      version: "0.3.0-dev",
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
      ],
      aliases: [
        "publish": [&git_tag/1, "hex.publish", "hex.docs"]
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
        :crypto,
        :inets
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
      {:phoenix, "~> 1.1.4", only: :test},
      {:timex, "~> 1.0.0", only: [:dev, :test]},
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

  defp git_tag(_args) do
    version_tag = case Version.parse(project[:version]) do
      {:ok, %Version{pre: []}} ->
        "v" <> project[:version]
      _ ->
        raise "Version should be a release version."
    end
    System.cmd "git", ["tag", "-a", version_tag, "-m", "Release #{version_tag}"]
    System.cmd "git", ["push", "--tags"]
  end
end
