defmodule DialyzerPlayground.MixProject do
  use Mix.Project

  def project do
    [
      app: :dialyzer_playground,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: [flags: ["-Wunmatched_returns", :error_handling, :underspecs]]
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
      # {:dialyxir, "~> 1.3", only: [:dev], runtime: false}
    ]
  end
end
