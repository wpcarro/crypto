defmodule Crypto.HTTP.Kraken do
  @moduledoc """
  HTTP Driver for Kraken communication. This module bakes the base URL into the requests. It also
  signs the requests according to the Kraken specifications.

  """

  alias Crypto.Kraken.OrderBook


  ################################################################################
  # Types
  ################################################################################

  @typep product :: :eth_usd | :eth_btc | :btc_usd


  ################################################################################
  # Constants
  ################################################################################

  @api_version "0"
  @base_url "https://api.kraken.com/#{@api_version}"
  @api_key Application.get_env(:crypto, :kraken_api_key)
  @api_secret Application.get_env(:crypto, :kraken_api_secret)



  ################################################################################
  # Private Helpers
  ################################################################################

  @doc """
  Fetches data from Kraken's public API.

  """
  @spec public_get(Path.t, keyword) :: HTTPoison.Response.t
  def public_get(endpoint, opts \\ []) do
    url =
      Path.join([@base_url, "public", endpoint])

    case HTTPoison.get!(url, opts) do
      %HTTPoison.Response{body: body} -> Poison.decode!(body)
    end
  end


  def get_order_book(product) do
    url =
      Path.join([@base_url, "public", "Depth"])

    asset_pair =
      to_asset_pair(product)

    headers =
      []

    params =
      [pair: asset_pair]

    case HTTPoison.get!(url, headers, params: params) do
      %HTTPoison.Response{body: body} ->
        %{"result" => result} =
          Poison.decode!(body)

        result |> Map.get(asset_pair) |> OrderBook.from_raw
    end
  end


  @doc """
  Fetches data from Kraken's private API.

  """
  @spec private_get(Path.t, keyword) :: HTTPoison.Response.t
  def private_get(endpoint, opts \\ []) do
    url =
      Path.join([@base_url, "private", endpoint])

    nonce =
      Timex.now |> Timex.to_unix

    body =
      %{"nonce" => nonce,
       }

    headers =
      %{"API-Key" => @api_key,
      }

    signed_headers =
      headers |> sign_headers(endpoint, body)

    HTTPoison.post!(url, body, signed_headers, opts)
  end



  ################################################################################
  # Private Helpers
  ################################################################################

  @spec sign_headers(HTTPoison.headers, Path.t, map) :: binary
  defp sign_headers(headers, endpoint, body \\ %{}) do
    hashed_data =
      :crypto.hash(:sha256, Poison.encode!(body))

    secret =
      Base.decode64!(@api_secret)

    signature =
      :crypto.hmac(:sha512, endpoint <> hashed_data, secret) |> Base.encode64

    headers |> Map.put("API-Sign", signature)
  end

  @spec to_asset_pair(product) :: binary
  def to_asset_pair(:eth_usd), do: "XETHZUSD"

end
