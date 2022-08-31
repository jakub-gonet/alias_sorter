defmodule AliasSorter.MixProject do
  use Mix.Project

  def project do
    [
      app: :alias_sorter,
      version: "0.2.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package()
    ]
  end

  defp package do
    [
      description: "Sorts and groups aliases in Elixir files.",
      maintainers: ["Jakub Gonet"],
      licenses: ["Apache-2.0"],
      links: %{
        "GitHub" => "https://github.com/jakub-gonet/alias_sorter"
      }
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.27", only: :dev, runtime: false},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false}
    ]
  end
end
