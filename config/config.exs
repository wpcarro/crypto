use Mix.Config


case true do
  true ->
    config :crypto,
      # Kraken
      kraken_api_key: File.read!("config/secrets/kraken_api_key.txt") |> String.trim,
      kraken_api_secret: File.read!("config/secrets/kraken_api_secret.txt") |> String.trim,
      # GDAX
      gdax_url: "https://api.gdax.com",
      gdax_api_key: File.read!("config/secrets/gdax_api_key.txt") |> String.trim,
      gdax_api_secret: File.read!("config/secrets/gdax_api_secret.txt") |> String.trim,
      gdax_api_password: File.read!("config/secrets/gdax_api_password.txt") |> String.trim,
      # Coinbase
      coinbase_btc_wallet: File.read!("config/secrets/coinbase_btc_wallet_address.txt") |> String.trim,
      coinbase_eth_wallet: File.read!("config/secrets/coinbase_eth_wallet_address.txt") |> String.trim,
      coinbase_ltc_wallet: File.read!("config/secrets/coinbase_ltc_wallet_address.txt") |> String.trim,
      coinbase_usd_wallet: File.read!("config/secrets/coinbase_usd_wallet_address.txt") |> String.trim

  false ->
    config :crypto,
      # Kraken
      kraken_api_key: File.read!("config/secrets/kraken_api_key.txt") |> String.trim,
      kraken_api_secret: File.read!("config/secrets/kraken_api_secret.txt") |> String.trim,
      # GDAX
      gdax_url: "https://api-public.sandbox.gdax.com",
      gdax_api_key: File.read!("config/secrets/gdax_sandbox_api_key.txt") |> String.trim,
      gdax_api_secret: File.read!("config/secrets/gdax_sandbox_api_secret.txt") |> String.trim,
      gdax_api_password: File.read!("config/secrets/gdax_sandbox_api_password.txt") |> String.trim
end
