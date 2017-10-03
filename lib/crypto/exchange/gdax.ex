defmodule Cryptocurrency.Exchange.GDAX do
  @moduledoc """
  Behaviour module implementing the `Cryptocurrency.Exchange` callbacks for GDAX.

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

  import ShorterMaps
  alias Cryptocurrency.Utils
  alias Cryptocurrency.Core.OrderBook
  alias Cryptocurrency.Exchange
  alias __MODULE__

  use Agent
  @behaviour Exchange



  ################################################################################
  # Constants
  ################################################################################

  @coinbase_eth_wallet Application.get_env(:cryptocurrency, :coinbase_eth_wallet)
  @coinbase_usd_wallet Application.get_env(:cryptocurrency, :coinbase_usd_wallet)



  ################################################################################
  # Callback Definitions
  ################################################################################

  @impl Exchange
  def start_link(opts \\ []) do
    balance =
      %{usd: 0.00, eth: 0.00}

    http_driver =
      Keyword.get(opts, :http_driver, GDAX.HTTP)

    state =
      ~M{balance, http_driver}

    Agent.start_link(fn -> state end, name: __MODULE__)
  end


  @impl Exchange
  def fetch_order_book(asset_pair) do
    endpoint =
      "/products/#{product_id(asset_pair)}/book"

    params =
      [level: 2]

    driver =
      Agent.get(__MODULE__, fn ~M{driver} -> driver end)

    with {:ok, ~M{body}}   <- apply(driver, :get, [endpoint, params: params]),
         {:ok, order_book} <- order_book_from_raw(body) do
      {:ok, order_book}
    end
  end


  @impl Exchange
  def transaction_fee(:eth_usd),
    do: 0.003

  def transaction_fee(:btc_usd),
    do: 0.0025

  def transaction_fee(:eth_btc),
    do: 0.003


  @impl Exchange
  def withdrawal_fee(_asset_pair),
    do: 0.0


  @impl Exchange
  def margin_funding_fee(_asset_pair),
    do: raise("Not impld")


  @impl Exchange
  def supported_assets,
    do: MapSet.new([:eth, :btc, :ltc, :usd, :eur, :gbp])


  @impl Exchange
  def supported_sides,
    do: MapSet.new([:buy, :sell])


  @impl Exchange
  def buy(opts),
    do: execute_order(:buy, opts)


  @impl Exchange
  def sell(opts),
    do: execute_order(:sell, opts)


  @impl Exchange
  def cancel(order_id) do
    HTTP.delete!("/orders/#{order_id}", decode: true)
  end


  @impl Exchange
  def pending_orders do
    HTTP.get!("/orders", decode: true)
  end


  @impl Exchange
  def send_to_exchange(opts) do
    asset =
      Keyword.fetch!(opts, :asset)

    volume =
      Keyword.fetch!(opts, :volume)

    exchange =
      Keyword.fetch!(opts, :exchange)

    address =
      apply(exchange, :wallet_address, [asset])

    body = %{
      amount: volume,
      currency: asset |> to_string(),
      crypto_address: address,
    }

    HTTP.post!("/withdrawals/crypto", body: body)
  end


  @impl Exchange
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


  @spec order_book_from_raw(iodata) :: {:ok, OrderBook.t} | {:error, :decode_error}
  defp order_book_from_raw(body) do
    %{"asks" => asks, "bids" => bids} =
      Poison.decode!(body)

    decode_entry = fn
      [price, size, order_count] ->
        %{price: Utils.parse_float(price),
          volume: Utils.parse_float(size),
          extra: %{order_count: order_count},
         }
    end

    struct!(OrderBook, asks: Enum.map(asks, decode_entry), bids: Enum.map(bids, decode_entry))
  rescue
    _ -> {:error, :decode_error}
  end


  @spec do_order_book_from_raw(map) :: {:ok, }
  defp do_order_book_from_raw(decoded) do
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
