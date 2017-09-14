defmodule Geobox.Mixfile do
  use Mix.Project

  def project do
    [app: :geobox,
     version: "0.1.0",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     description: description(),
     package: package(),
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [extra_applications: [:logger]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:my_dep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:my_dep, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [{:geohash, "~> 1.0"},
     {:ex_doc, ">= 0.0.0", only: :dev}]
  end

  defp description() do
    "Geobox - lookup set of overlapping geohashes within bounding box or radius covering all intersections in given resolution, usefull for proximity search."
  end

  defp package do
    [licenses: ["MIT"],
     maintainers: ["Bartłomiej Różański"],
     links: %{"GitHub" => "https://github.com/bartekupartek/geobox"}]
  end
end
