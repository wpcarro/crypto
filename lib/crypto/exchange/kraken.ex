defmodule Crypto.Exchange.Kraken do
  @moduledoc """
  Behaviour module implementing the `Crypto.Exchange` callbacks for Kraken.

  """

  alias Crypto.Utils
  alias Crypto.Core.OrderBook
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

    case HTTP.public_get("Depth", params: params) do
      %HTTPoison.Response{body: body} ->
        res =
          Poison.decode!(body)

        get_in(res, ["result", asset_pair]) |> order_book_from_raw
    end
  end


  def transaction_fee(_),
    do: 0.0026


  def withdrawal_fee(_),
    do: 0.0


  def execute_orders(_orders),
    do: :ok


  def supported_assets,
    do: raise("Not implemented")


  def supported_sides,
    do: MapSet.new([:buy, :sell])



  ################################################################################
  # Private Helpers
  ################################################################################

  @spec to_asset_pair(Exchange.asset_pair) :: binary
  defp to_asset_pair(:eth_usd), do: "XETHZUSD"
  defp to_asset_pair(:btc_usd), do: "XXBTZUSD"


  @spec order_book_from_raw(map) :: OrderBook.t
  defp order_book_from_raw(raw) do
    %{"asks" => asks, "bids" => bids} =
      raw

    decode_entry = fn
      [price, size, timestamp] ->
        %{price: Utils.parse_float(price),
          volume: Utils.parse_float(size),
          extra: %{timestamp: Timex.from_unix(timestamp)},
         }
    end

    struct(OrderBook, asks: Enum.map(asks, decode_entry), bids: Enum.map(bids, decode_entry))
  end

end
