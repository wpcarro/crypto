defmodule Crypto.Exchange.Bitfinex.HTTP do
  @moduledoc """
  HTTP Driver for GDAX communication. This module bakes the base URL into the requests. It also
  signs the requests according to the GDAX specifications.

  """



  ################################################################################
  # Constants
  ################################################################################

  @api_version "v1"
  @base_url "https://api.bitfinex.com/#{@api_version}"
  @api_key Application.get_env(:crypto, :bitfinex_api_key)
  @api_secret Application.get_env(:crypto, :bitfinex_api_secret)



  ################################################################################
  # Public API
  ################################################################################

  def public_get!(endpoint, opts \\ []) do
    url =
      Path.join(@base_url, endpoint)

    decode? =
      Keyword.get(opts, :decode, false)

    result =
      HTTPoison.get!(url, opts)

    case decode? do
      true  -> result |> Map.get(:body) |> Poison.decode!
      false -> result
    end
  end


  def private_post!(endpoint, opts \\ []) do
    endpoint =
      Path.join("auth", endpoint)

    url =
      Path.join(@base_url, endpoint)

    raw_body =
      Keyword.get(opts, :body, %{}) |> Poison.encode!

    nonce =
      Timex.now |> Timex.to_unix |> to_string

    signed_headers = %{
      "bfx-nonce" => nonce,
      "bfx-apikey" => @api_key,
      "Content-Type" => "application/json",
    } |> sign_headers(endpoint, nonce, raw_body)

    result =
      HTTPoison.post!(url, raw_body, signed_headers, opts)

    case Keyword.get(opts, :decode, false) do
      true  -> result |> Map.get(:body) |> Poison.decode!
      false -> result
    end
  end

  ################################################################################
  # Private Helpers
  ################################################################################

  @spec sign_headers(map, Path.t, binary, binary) :: map
  defp sign_headers(headers, endpoint, nonce, raw_body) do
    value =
      Path.join(["/api", @api_version, endpoint]) <> nonce <> raw_body

    signature =
      :crypto.hmac(:sha384, @api_secret, value) |> Base.encode64

    headers |> Map.put("bfx-signature", signature)
  end

end
