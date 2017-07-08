defmodule Crypto.Exchange.Gemini do
  @moduledoc """
  Behaviour module implementing the `Crypto.Exchange` callbacks for Kraken.

  """

  alias Crypto.Core.OrderBook
  alias Crypto.Exchange.Gemini.HTTP

  @behaviour Crypto.Exchange



  ################################################################################
  # Callback Definitions
  ################################################################################

  def fetch_order_book(asset_pair) do
    asset_pair =
      to_asset_pair(asset_pair)

    case HTTP.public_get("book/#{asset_pair}") do
      %HTTPoison.Response{body: body} ->
        Poison.decode!(body) |> order_book_from_raw
    end
  end


  def transaction_fee(_),
    do: raise("Not implementing")


  def execute_orders(_order),
    do: :ok



  ################################################################################
  # Private Helpers
  ################################################################################

  @spec to_asset_pair(Exchange.asset_pair) :: binary
  defp to_asset_pair(:eth_usd), do: "ethusd"
  defp to_asset_pair(:btc_usd), do: "btcusd"


  @spec order_book_from_raw(map) :: OrderBook.t
  defp order_book_from_raw(raw) do
    %{"asks" => asks, "bids" => bids} =
      raw

    decode_entry = fn
      %{"price" => price, "amount" => amount, "timestamp" => timestamp} ->
        %{price: parse_float(price),
          volume: parse_float(amount),
          extra: %{timestamp: parse_int(timestamp) |> Timex.from_unix},
         }
    end

    struct(OrderBook, asks: Enum.map(asks, decode_entry), bids: Enum.map(bids, decode_entry))
  end


  @spec parse_int(binary) :: integer
  defp parse_int(input) do
    {result, ""} =
      Integer.parse(input)

    result
  end


  @spec parse_float(binary) :: float
  defp parse_float(input) do
    {result, ""} =
      Float.parse(input)

    result
  end

end
