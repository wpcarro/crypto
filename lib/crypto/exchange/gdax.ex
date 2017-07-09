defmodule Crypto.Exchange.GDAX do
  @moduledoc """
  Behaviour module implementing the `Crypto.Exchange` callbacks for GDAX.

  """

  alias Crypto.Utils
  alias Crypto.Core.OrderBook
  alias Crypto.Exchange
  alias Crypto.Exchange.GDAX.HTTP

  @behaviour Crypto.Exchange



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


  def transaction_fee(:eth),
    do: 0.003

  def transaction_fee(_asset),
    do: 0.0025


  def withdrawal_fee(_asset),
    do: 0.0025


  def execute_orders(_orders),
    do: :ok


  def supported_assets,
    do: MapSet.new([:eth, :btc, :ltc, :usd, :eur, :gbp])



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


  @spec buy(keyword) :: :ok
  def buy(opts) do
    product_id =
      Keyword.fetch!(opts, :asset_pair) |> product_id

    price =
      Keyword.fetch!(opts, :price)

    volume =
      Keyword.fetch!(opts, :volume)

    body =
      %{side: "buy",
        product_id: product_id,
        price: price |> to_string,
        size: volume |> to_string,
        overdraft_enabled: true
       }

    HTTP.post!("/orders", body: body)
  end

end
