defmodule Cryptocurrency.Exchange.Bithumb do
  @moduledoc """
  Behaviour module implementing the `Cryptocurrency.Exchange` callbacks for
  the Korean exchange, Bithumb.

  Fees are outlined [here](https://www.bithumb.com/u1/US138).

  """

  import ShorterMaps

  alias Cryptocurrency.Utils
  alias Cryptocurrency.Core.OrderBook
  alias Cryptocurrency.Core.OrderBook.Entry
  alias Cryptocurrency.{Exchange, Forex}
  alias Cryptocurrency.Exchange.Bithumb.HTTP

  @behaviour Exchange



  ################################################################################
  # Callback Definitions
  ################################################################################

  @impl Exchange
  def fetch_order_book(asset_pair) do
    [to, from] =
      asset_pair
      |> Atom.to_string()
      |> String.split("_")

    # need to get the KRW:USD exchange rate since Bithumb returns KRW prices
    exchange_rate =
      Forex.rate(from: :krw, to: String.to_atom(from))

    endpoint =
      "orderbook/#{to}"

    params =
      [count: 10]

    case HTTP.public_get!(endpoint, params: params) do
      %HTTPoison.Response{body: body} ->
        Poison.decode!(body)
        |> order_book_from_raw(exchange_rate)
    end
  end


  # Fees are outlined here: https://www.bithumb.com/u1/US138
  @impl Exchange
  def transaction_fee(_asset_pair),
    do: 0.0015


  # Fees are outlined here: https://www.bithumb.com/u1/US138
  @impl Exchange
  def withdrawal_fee(_asset_pair),
    do: 0.0


  @impl Exchange
  def margin_funding_fee(_asset_pair),
    do: raise("Not impld")


  # Unsure whether or not Bithumb supports USDs. They are listed on the
  # Exchange page, which seems promising.
  @impl Exchange
  def supported_assets do
    MapSet.new([
      :btc, :eth, :dash, :ltc, :etc, :xrp, :bch, :xmr, :zec, :qtum, :btg, :eos,
      :krw
    ])
  end


  # We need to ensure that Bithumb can short sell and what that looks like.
  # Most exchanges that support short selling do not support "naked shorts",
  # which means that we need a base level of currency in those exchanges'
  # balances before the short-selling is permitted.
  @impl Exchange
  def supported_sides,
    do: MapSet.new([:buy, :sell])


  @impl Exchange
  def buy(opts) do
  end


  @impl Exchange
  def sell(opts) do
  end


  @impl Exchange
  def cancel(order_id) do
  end


  @impl Exchange
  def pending_orders do
  end


  @impl Exchange
  def send_to_exchange(opts) do
  end



  ################################################################################
  # Private Helpers
  ################################################################################

  # Parses the Poison decoded JSON response from Bithumb into an OrderBook.t.
  # This function uses the current KRW:USD exchange rate to map the order book
  # into a supported currency.
  @spec order_book_from_raw(map, Forex.exchange_rate) :: OrderBook.t
  defp order_book_from_raw(raw, exchange_rate) do
    %{"asks" => asks, "bids" => bids} =
      Map.fetch!(raw, "data")

    decode_entry = fn
      ~m{quantity, price} ->
        %Entry{
          price: Utils.parse_float(price) * exchange_rate,
          volume: Utils.parse_float(quantity),
         }
    end

    struct(
      OrderBook,
      asks: Enum.map(asks, decode_entry),
      bids: Enum.map(bids, decode_entry)
    )
  end
end

