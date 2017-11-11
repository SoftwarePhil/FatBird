defmodule FatBird.Mixfile do
  use Mix.Project

  def project do
    [
      app: :fat_bird,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {FatBird, []},
      extra_applications: [:logger, :couchdb_connector]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:couchdb_connector, "~> 0.5.0"}
    ]
  end
end
