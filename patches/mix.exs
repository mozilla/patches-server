defmodule Patches.MixProject do
  use Mix.Project

  def project do
    [
      app: :patches,
      version: "0.1.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [
        :logger,
        :plug_cowboy,
      ],
      mod: {Patches.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:httpoison, "~> 1.5.0"},
      {:poison, "~> 4.0.1"},
      {:plug_cowboy, "~> 2.0"},
    ]
  end
end
