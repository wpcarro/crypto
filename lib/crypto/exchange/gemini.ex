defmodule Cryptocurrency.Exchange.Gemini do
  @moduledoc """
  Behaviour module implementing the `Cryptocurrency.Exchange` callbacks for Kraken.

  At this time, Gemini has dropped support for its margin trading through its API. This means that
  our algorithm can only buy from Gemini.

  """

  alias Cryptocurrency.Utils
  alias Cryptocurrency.Core.OrderBook
  alias Cryptocurrency.Exchange.Gemini.HTTP

  @behaviour Cryptocurrency.Exchange



  ################################################################################
  # Constants
  ################################################################################

  @gemini_btc_wallet Application.get_env(:cryptocurrency, :gemini_btc_wallet)
  @gemini_eth_wallet Application.get_env(:cryptocurrency, :gemini_eth_wallet)



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


  def transaction_fee(_asset),
    do: 0.0025


  def withdrawal_fee(_asset),
    do: 0.0


  def execute_orders(_order),
    do: :ok


  def supported_assets,
    do: MapSet.new([:eth, :btc, :usd])


  def supported_sides,
    do: MapSet.new([:buy])


  def send_to_exchange(opts) do
    asset =
      Keyword.fetch!(opts, :asset) |> to_string

    volume =
      Keyword.fetch!(opts, :volume) |> to_string

    exchange =
      Keyword.fetch!(opts, :exchange)

    address =
      apply(exchange, :wallet_address, [asset])

    api_version =
      HTTP.api_version

    request =
      "/#{api_version}/withdraw/#{asset}"

    body = %{
      request: request,
      amount: volume,
      nonce: "???",
      address: address,
    }

    case HTTP.post!("/withdraw/#{asset}", body: body) do
      %HTTPoison.Response{body: body} ->
        %{"destination" => ^address, "amount" => ^volume} =
          Poison.decode!(body)

        :ok

      error ->
        IO.inspect("Withdrawal error. #{inspect(error)}")
    end
  end


  def wallet_address(:eth), do: @gemini_eth_wallet
  def wallet_address(:btc), do: @gemini_btc_wallet



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
        %{price: Utils.parse_float(price),
          volume: Utils.parse_float(amount),
          extra: %{timestamp: Utils.parse_int(timestamp) |> Timex.from_unix},
         }
    end

    struct(OrderBook, asks: Enum.map(asks, decode_entry), bids: Enum.map(bids, decode_entry))
  end

end
