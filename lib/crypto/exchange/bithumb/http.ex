defmodule Cryptocurrency.Exchange.Bithumb.HTTP do
  @moduledoc """
  HTTP Driver for interacting with the Bithumb exchange.

  ## Rate Limiting Information

  As so many of these exchanges tend to be, Bithumb is rate-limited. Here are
  the restrictions.

  ### Public API
  * 20 request available per second.
  * If the request exceeds 20 calls per second, API usage will be limited,
    and also the administrator's approval is reqqired to remove the limitation.
    (Phone contact required)

  ### Private API
  * 10 request available per second.
  * If the request exceeds 10 calls, API usage will be limited for 5 minutes.

  """



  ################################################################################
  # Constants
  ################################################################################

  @base_url Application.get_env(:cryptocurrency, :bithumb_url)
  @api_key Application.get_env(:cryptocurrency, :bithumb_api_key)
  @api_secret Application.get_env(:cryptocurrency, :bithumb_api_secret)



  ################################################################################
  # Public API
  ################################################################################

  @doc """
  Makes a request to the Bithumb API using a publically accessible endpoint.

  """
  def public_get!(endpoint, opts \\ []) do
    url =
      Path.join([@base_url, "public", endpoint])

    headers =
      %{}

    decode? =
      Keyword.get(opts, :decode, false)

    result =
      HTTPoison.get!(url, headers, opts)

    case decode? do
      true  -> result |> Map.get(:body) |> Poison.decode!
      false -> result
    end
  end


  @doc """
  Makes a request to a Bithumb API private endpoint.

  """
  def private_get!(endpoint, opts \\ []) do
    url =
      Path.join(@base_url, endpoint)

    headers =
      %{"apiKey" => @api_key,
        "secretKey" => @secret_key,
      }

    decode? =
      Keyword.get(opts, :decode, false)

    result =
      HTTPoison.get!(url, headers, opts)

    case decode? do
      true  -> result |> Map.get(:body) |> Poison.decode!
      false -> result
    end
  end

end

