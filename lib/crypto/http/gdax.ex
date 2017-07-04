defmodule Crypto.HTTP.GDAX do
  @moduledoc """
  HTTP Driver for GDAX communication. This module bakes the base URL into the requests. It also
  signs the requests according to the GDAX specifications.

  """

  alias __MODULE__
  alias Crypto.GDAX.OrderBook


  ################################################################################
  # Types
  ################################################################################

  @typep product :: :eth_usd | :eth_btc | :btc_usd



  ################################################################################
  # Constants
  ################################################################################

  @base_url "https://api.gdax.com"
  @api_key Application.get_env(:crypto, :coinbase_api_key)
  @api_secret Application.get_env(:crypto, :coinbase_api_secret)



  ################################################################################
  # Private Helpers
  ################################################################################

  def get(endpoint, opts \\ []) do
    url =
      Path.join(@base_url, endpoint)

    headers =
      %{"CB-ACCESS-KEY" => @api_key,
        "CB-ACCESS-TIMESTAMP" => Timex.now |> Timex.to_unix,
       }

    signed_headers =
      headers |> sign_headers("get", endpoint)

    case HTTPoison.get!(url, signed_headers, opts) do
      %HTTPoison.Response{body: body} -> Poison.decode!(body)
    end
  end


  @doc """
  Returns a list of open orders for a product.

  """
  def get_order_book(product) do
    endpoint =
      "/products/#{product_id(product)}/book"

    params =
      [level: 2]

    GDAX.get(endpoint, params: params) |> OrderBook.from_raw
  end



  ################################################################################
  # Private Helpers
  ################################################################################

  @spec sign_headers(HTTPoison.headers, String.t, Path.t, map) :: binary
  defp sign_headers(headers, method, endpoint, body \\ %{}) do
    %{"CB-ACCESS-TIMESTAMP" => timestamp} =
      headers

    data =
      inspect(timestamp) <> String.upcase(method) <> endpoint <> Poison.encode!(body)

    key =
      Base.decode64!(@api_secret)

    signature =
      :crypto.hmac(:sha256, key, data) |> Base.encode64

    headers |> Map.put("CB-ACCESS-SIGN", signature)
  end

  @spec product_id(product) :: binary
  defp product_id(:eth_usd), do: "ETH-USD"
  defp product_id(:eth_btc), do: "ETH-BTC"
  defp product_id(:btc_usd), do: "BTC-USD"

end
