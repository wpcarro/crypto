defmodule Crypto.Exchange.Kraken do
  @moduledoc """
  Behaviour module implementing the `Crypto.Exchange` callbacks for Kraken.

  """

  import ShorterMaps
  alias Crypto.Core.{Order, OrderBook}
  alias Crypto.Exchange.Kraken.HTTP

  @behaviour Crypto.Exchange



  ################################################################################
  # Callback Definitions
  ################################################################################

  def fetch_order_book(asset_pair) do
    asset_pair =
      to_asset_pair(asset_pair)

    params =
      [pair: asset_pair]

    case HTTP.public_get("Depth", [], params: params) do
      res when is_map(res) ->
        get_in(res, ["result", asset_pair]) |> order_book_from_raw
    end
  end


  def transaction_fee,
    do: 0.0026


  def execute_orders(_orders) do
    :ok
  end



  ################################################################################
  # Private Helpers
  ################################################################################

  @spec to_asset_pair(Exchange.asset_pair) :: binary
  defp to_asset_pair(:eth_usd), do: "XETHZUSD"


  @spec order_book_from_raw(map) :: OrderBook.t
  defp order_book_from_raw(raw) do
    %{"asks" => asks, "bids" => bids} =
      raw

    decode_entry = fn
      [price, size, timestamp] ->
        %{price: parse_float(price),
          volume: parse_float(size),
          extra: %{timestamp: Timex.from_unix(timestamp)},
         }
    end

    struct(OrderBook, asks: Enum.map(asks, decode_entry), bids: Enum.map(bids, decode_entry))
  end


  @spec parse_float(binary) :: float
  defp parse_float(input) do
    {result, ""} =
      Float.parse(input)

    result
  end
end
