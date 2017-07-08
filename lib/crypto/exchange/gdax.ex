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

    HTTP.get(endpoint, params: params) |> order_book_from_raw
  end


  def transaction_fee,
    do: 0.003


  def execute_orders(_orders),
    do: :ok



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

end
