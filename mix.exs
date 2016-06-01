defmodule Tracker.Mixfile do
    use Mix.Project

    def project do
        [
            app: :tracker,
            version: "0.0.1",
            elixir: "~> 1.2",
            build_embedded: Mix.env == :prod,
            start_permanent: Mix.env == :prod,
            deps: deps
        ]
    end

    def application do
        [
            applications: [:logger, :cowboy, :httpoison, :instream],
            mod: {Tracker, []}
        ]
    end


    defp deps do
        [
            {:poison, "~> 2.1"},
            {:cowboy, "~> 1.0"},
            {:httpoison, "~> 0.8.3"},
            {:placemeter, github: "NationalAssociationOfRealtors/PlacemeterAPI", branch: "master"},
            {:instream, "~> 0.12"},
        ]
    end
end
