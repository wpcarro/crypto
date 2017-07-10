defmodule Crypto.Exchange.GDAX do
  @moduledoc """
  Behaviour module implementing the `Crypto.Exchange` callbacks for GDAX.

  GDAX supports margin trading through its API meaning our algorithm can take both buy and sell
  sides of arbitrage opportunities.


  ## Margin Trading

  GDAX supports margin trading. This means both the buy side and the sell side can be relied upon in
  the arbitrage strategy.

  > A Margin Order is valid if it would not exceed the Trader’s Margin Funding Limit or cause the
  > Trader’s Margin Ratio to fall to or below the Initial Maintenance Requirement.

  ## Margin TTL

  Margin funding accounts must be closed with 27 days and 22 hours.

  ## Margin Ratio

  There are Margin Ratios for each order book (i.e. :eth_usd, :btc_usd). The Margin Ratio is
  calculated as such:

  ```
  margin_ratio = equity / outstanding_margin_funding
  # where
  equity = total_asset_value - outstanding_margin_funding
  # where
  total_asset_value = asset_count * last_trade_price
  # where
  outstanding_margin_funding = asset_count * last_trade_price
  ```

  ## Margin Maintenance Requirements

  Margin Ratios must be above Margin Maintenance Requirements.

  For more information, [see here](https://support.gdax.com/customer/portal/articles/2725970-trading-rules).

  """

  alias Crypto.Utils
  alias Crypto.Core.OrderBook
  alias Crypto.Exchange
  alias Crypto.Exchange.GDAX.HTTP

  @behaviour Crypto.Exchange



  ################################################################################
  # Callback Definitions
  ################################################################################

  @coinbase_btc_wallet Application.get_env(:crypto, :coinbase_btc_wallet)
  @coinbase_eth_wallet Application.get_env(:crypto, :coinbase_eth_wallet)
  @coinbase_ltc_wallet Application.get_env(:crypto, :coinbase_ltc_wallet)
  @coinbase_usd_wallet Application.get_env(:crypto, :coinbase_usd_wallet)



  ################################################################################
  # Callback Definitions
  ################################################################################

  def fetch_order_book(asset_pair) do
    endpoint =
      "/products/#{product_id(asset_pair)}/book"

    params =
      [level: 2]

    case HTTP.get!(endpoint, params: params) do
      %HTTPoison.Response{body: body} ->
        Poison.decode!(body) |> order_book_from_raw
    end
  end


  def transaction_fee(:eth_usd),
    do: 0.003

  def transaction_fee(:btc_usd),
    do: 0.0025


  def withdrawal_fee(:eth_usd),
    do: 0.0

  def withdrawal_fee(:btc_usd),
    do: 0.0


  def execute_orders(_orders),
    do: :ok


  def supported_assets,
    do: MapSet.new([:eth, :btc, :ltc, :usd, :eur, :gbp])


  def supported_sides,
    do: MapSet.new([:buy, :sell])


  def sell(opts),
    do: execute_order(:sell, opts)


  def buy(opts),
    do: execute_order(:buy, opts)


  def orders do
    HTTP.get!("/orders", decode: true)
  end


  def cancel(order_id) do
    HTTP.delete!("/orders/#{order_id}", decode: true)
  end


  def send_to_exchange(opts) do
    asset =
      Keyword.fetch!(opts, :asset) |> to_string

    volume =
      Keyword.fetch!(opts, :volume)

    exchange =
      Keyword.fetch!(opts, :exchange)

    address =
      apply(exchange, :wallet_address, [asset])

    body = %{
      amount: volume,
      currency: asset,
      crypto_address: address,
    }

    HTTP.post!("/withdrawals/crypto", body: body)
  end


  def wallet_address(:eth), do: @coinbase_eth_wallet
  def wallet_address(:btc), do: @coinbase_btc_wallet
  def wallet_address(:ltc), do: @coinbase_ltc_wallet
  def wallet_address(:usd), do: @coinbase_usd_wallet



  ################################################################################
  # Private Helpers
  ################################################################################

  @spec product_id(Exchange.asset_pair) :: binary
  defp product_id(:eth_usd), do: "ETH-USD"
  defp product_id(:eth_btc), do: "ETH-BTC"
  defp product_id(:btc_usd), do: "BTC-USD"


  @spec order_book_from_raw(map) :: OrderBook.t
  defp order_book_from_raw(raw) do
    %{"asks" => asks, "bids" => bids} =
      raw

    decode_entry = fn
      [price, size, order_count] ->
        %{price: Utils.parse_float(price),
          volume: Utils.parse_float(size),
          extra: %{order_count: order_count},
         }
    end

    struct(OrderBook, asks: Enum.map(asks, decode_entry), bids: Enum.map(bids, decode_entry))
  end


  @spec execute_order(Order.side, keyword) :: map
  defp execute_order(side, opts) do
    product_id =
      Keyword.fetch!(opts, :asset_pair) |> product_id

    price =
      Keyword.fetch!(opts, :price)

    volume =
      Keyword.fetch!(opts, :volume)

    margin? =
      Keyword.get(opts, :margin, false)

    body = %{
      side: side,
      product_id: product_id,
      price: price |> to_string,
      size: volume |> to_string,
      overdraft_enabled: margin?,
    }

    case HTTP.post!("/orders", body: body) do
      %HTTPoison.Response{body: body} -> Poison.decode!(body)
    end
  end

end
