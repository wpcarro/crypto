defmodule Crypto.Exchange.GDAX.HTTP do
  @moduledoc """
  HTTP Driver for GDAX communication. This module bakes the base URL into the requests. It also
  signs the requests according to the GDAX specifications.

  """



  ################################################################################
  # Constants
  ################################################################################

  @base_url Application.get_env(:crypto, :gdax_url) |> IO.inspect
  @api_key Application.get_env(:crypto, :gdax_api_key)
  @api_secret Application.get_env(:crypto, :gdax_api_secret)
  @api_password Application.get_env(:crypto, :gdax_api_password)



  ################################################################################
  # Public API
  ################################################################################

  def get!(endpoint, opts \\ []) do
    url =
      Path.join(@base_url, endpoint)

    headers =
      %{"CB-ACCESS-KEY" => @api_key,
        "CB-ACCESS-PASSPHRASE" => @api_password,
        "CB-ACCESS-TIMESTAMP" => Timex.now |> Timex.to_unix,
        "Content-Type" => "application/json"
       }

    signed_headers =
      headers |> sign_headers("get", endpoint)

    HTTPoison.get!(url, signed_headers, opts)
  end


  def post!(endpoint, opts \\ []) do
    url =
      Path.join(@base_url, endpoint)

    body =
      Keyword.get(opts, :body, %{})

    headers =
      %{"CB-ACCESS-KEY" => @api_key,
        "CB-ACCESS-PASSPHRASE" => @api_password,
        "CB-ACCESS-TIMESTAMP" => Timex.now |> Timex.to_unix,
        "Content-Type" => "application/json"
       }

    signed_headers =
      headers |> sign_headers("post", endpoint, body)

    HTTPoison.post!(url, Poison.encode!(body), signed_headers, opts)
  end



  ################################################################################
  # Private Helpers
  ################################################################################

  @spec sign_headers(HTTPoison.headers, String.t, Path.t, map) :: binary
  defp sign_headers(headers, method, endpoint, body \\ :empty) do
    timestamp =
      Map.fetch!(headers, "CB-ACCESS-TIMESTAMP")

    encoded_body =
      case body do
        :empty -> ""
        body when is_map(body) -> Poison.encode!(body)
      end

    data =
      inspect(timestamp) <> String.upcase(method) <> endpoint <> encoded_body

    IO.puts(data)

    key =
      Base.decode64!(@api_secret)

    signature =
      :crypto.hmac(:sha256, key, data) |> Base.encode64

    headers |> Map.put("CB-ACCESS-SIGN", signature)
  end

end
