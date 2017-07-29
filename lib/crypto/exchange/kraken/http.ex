defmodule Cryptocurrency.Exchange.Kraken.HTTP do
  @moduledoc """
  HTTP Driver for Kraken communication. This module bakes the base URL into the requests. It also
  signs the requests according to the Kraken specifications.

  """


  ################################################################################
  # Constants
  ################################################################################

  @api_version "0"
  @base_url "https://api.kraken.com/#{@api_version}"
  @api_key Application.get_env(:cryptocurrency, :kraken_api_key)
  @api_secret Application.get_env(:cryptocurrency, :kraken_api_secret)



  ################################################################################
  # Public API
  ################################################################################

  @doc """
  Fetches data from Kraken's public API. Forwards `headers` and `opts` to the `HTTPoison.get!/3`
  function.

  """
  @spec public_get(Path.t, keyword) :: HTTPoison.Response.t
  def public_get(endpoint, opts \\ []) do
    url =
      Path.join([@base_url, "public", endpoint])

    decode? =
      Keyword.get(opts, :decode, false)

    result =
      HTTPoison.get!(url, [], opts)

    case decode? do
      true  -> result |> Map.get(:body) |> Poison.decode!
      false -> result
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
  defp to_asset_pair(:eth_usd), do: "XETHZUSD"

end
