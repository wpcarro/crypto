defmodule Crypto.Exchange.Bitfinex do
  @moduledoc """
  Behaviour module implementing the `Crypto.Exchange` callbacks for Bitfinex.

  Bitfinex supports margin trading through its API meaning our algorithm can take both buy and sell
  sides of arbitrage opportunities.

  Bitfinex's maximum number of allowable significant digits for orders is 5. Any digit that exceeds
  this is truncated.

  ```
  E.g. 5.091287 => 5.09128 # the 7 is dropped
  ```

  # Margin Trading

  Margin trading uses the funds put up on the Margin Funding market. There are rates associated with
  the borrowing that need to be repaid and accounted for in the profit calculation.

  """

  alias Crypto.Utils
  alias Crypto.Core.OrderBook
  alias Crypto.Exchange.Bitfinex.HTTP

  @behaviour Crypto.Exchange



  ################################################################################
  # Callback Definitions
  ################################################################################

  def fetch_order_book(asset_pair) do
    endpoint =
      "/book/#{product_id(asset_pair)}"

    case HTTP.public_get!(endpoint, decode: true) do
      body when is_map(body) -> order_book_from_raw(body)
    end
  end


  def transaction_fee(_asset_pair),
    do: 0.002


  def withdrawal_fee(_asset_pair),
    do: 0.0


  def margin_funding_fee(_asset_pair),
    do: 0.003


  def supported_assets,
    do: MapSet.new([])


  def supported_sides,
    do: MapSet.new([:buy, :sell])



  ################################################################################
  # Private Helpers
  ################################################################################


  @spec product_id(Exchange.asset_pair) :: binary
  defp product_id(:eth_usd), do: "ethusd"
  defp product_id(:eth_btc), do: "ethbtc"
  defp product_id(:btc_usd), do: "btcusd"


  @spec order_book_from_raw(map) :: OrderBook.t
  defp order_book_from_raw(raw) do
    %{"asks" => asks, "bids" => bids} =
      raw

    decode_entry = fn
      %{"amount" => amount, "price" => price, "timestamp" => timestamp} ->
        %{price: Utils.parse_float(price),
          volume: Utils.parse_float(amount),
          extra: %{timestamp: Utils.parse_int(timestamp) |> Timex.to_unix},
         }
    end

    struct(OrderBook, asks: Enum.map(asks, decode_entry), bids: Enum.map(bids, decode_entry))
  end
end
