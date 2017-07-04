use Mix.Config

config :crypto,
  kraken_api_key: File.read!("config/secrets/kraken_api_key.txt") |> String.trim,
  kraken_api_secret: File.read!("config/secrets/kraken_api_secret.txt") |> String.trim,
  coinbase_api_key: File.read!("config/secrets/coinbase_api_key.txt") |> String.trim,
  coinbase_api_secret: File.read!("config/secrets/coinbase_api_secret.txt") |> String.trim
