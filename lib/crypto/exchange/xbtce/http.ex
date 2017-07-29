defmodule Cryptocurrency.Exchange.XBTCE.HTTP do
  @moduledoc """
  HTTP Driver for xBTCe communication. This module bakes the base URL into the requests. It also
  signs the requests per the xBTCe specifications.

  ## Rate Limiting

  Public API: xBTCe limits 10 requests a second

  429s are sent to signal the client to backoff.

  """



  ################################################################################
  # Constants
  ################################################################################

  @api_version "v1"
  @base_url "https://cryptottlivewebapi.xbtce.net:8443/api/#{@api_version}"



  ################################################################################
  # Public API
  ################################################################################

  @doc """
  Fetches data from xBTCe's public API. Forwards `headers` and `opts` to the `HTTPoison.get!/3`
  function.

  """
  @spec public_get(Path.t, keyword, keyword) :: HTTPoison.Response.t
  def public_get(endpoint, headers \\ [], opts \\ []) do
    url =
      Path.join([@base_url, "public", endpoint])

    HTTPoison.get!(url, headers, opts)
  end

end
