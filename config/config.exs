use Mix.Config

shared_config = [
  # Kraken
  kraken_api_key: File.read!("config/secrets/kraken_api_key.txt") |> String.trim,
  kraken_api_secret: File.read!("config/secrets/kraken_api_secret.txt") |> String.trim,
  # Coinbase
  coinbase_btc_wallet: File.read!("config/secrets/coinbase_btc_wallet.txt") |> String.trim,
  coinbase_eth_wallet: File.read!("config/secrets/coinbase_eth_wallet.txt") |> String.trim,
  coinbase_ltc_wallet: File.read!("config/secrets/coinbase_ltc_wallet.txt") |> String.trim,
  coinbase_usd_wallet: File.read!("config/secrets/coinbase_usd_wallet.txt") |> String.trim,
  # Gemini
  gemini_api_key: File.read!("config/secrets/gemini_api_key.txt") |> String.trim,
  gemini_api_secret: File.read!("config/secrets/gemini_api_secret.txt") |> String.trim,
  gemini_btc_wallet: File.read!("config/secrets/gemini_btc_wallet.txt") |> String.trim,
  gemini_eth_wallet: File.read!("config/secrets/gemini_eth_wallet.txt") |> String.trim,
  # Bitfinex
  bitfinex_api_key: File.read!("config/secrets/bitfinex_api_key.txt") |> String.trim,
  bitfinex_api_secret: File.read!("config/secrets/bitfinex_api_secret.txt") |> String.trim,
  # Bitmex
  bitmex_api_key: File.read!("config/secrets/bitmex_api_key.txt") |> String.trim,
  bitmex_api_secret: File.read!("config/secrets/bitmex_api_secret.txt") |> String.trim
]

sandbox_config = Keyword.merge(shared_config, [
  # GDAX
  gdax_url: "https://api-public.sandbox.gdax.com",
  gdax_api_key: File.read!("config/secrets/gdax_sandbox_api_key.txt") |> String.trim,
  gdax_api_secret: File.read!("config/secrets/gdax_sandbox_api_secret.txt") |> String.trim,
  gdax_api_password: File.read!("config/secrets/gdax_sandbox_api_password.txt") |> String.trim,
])

production_config = Keyword.merge(shared_config, [
  # GDAX
  gdax_url: "https://api.gdax.com",
  gdax_api_key: File.read!("config/secrets/gdax_api_key.txt") |> String.trim,
  gdax_api_secret: File.read!("config/secrets/gdax_api_secret.txt") |> String.trim,
  gdax_api_password: File.read!("config/secrets/gdax_api_password.txt") |> String.trim,
])


sandbox? = true

case sandbox? do
  true  -> config :cryptocurrency, sandbox_config
  false -> config :cryptocurrency, production_config
end
