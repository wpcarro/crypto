use Mix.Config

config :crypto,
  kraken_api_key: System.get_env("KRAKEN_API_KEY"),
  kraken_api_secret: System.get_env("KRAKEN_API_SECRET"),
  coinbase_api_key: System.get_env("COINBASE_API_KEY"),
  coinbase_api_secret: System.get_env("COINBASE_API_SECRET")
