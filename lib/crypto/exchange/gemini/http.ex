defmodule Cryptocurrency.Exchange.Gemini.HTTP do
  @moduledoc """
  HTTP Driver for Gemini communication. This module bakes the base URL into the requests. It also
  signs the requests according to the Gemini specifications.

  ## Rate Limiting

  Public API: Gemini limits requests to 120 per minute. Do not exceed 1 request per second.
  Private API: Gemini limits requests to 600 per minute. Do not exceed 5 request per second.

  429s are sent to signal the client to backoff.

  """



  ################################################################################
  # Constants
  ################################################################################

  @api_version "v1"
  @base_url "https://api.gemini.com/#{@api_version}"
  @gemini_api_key Application.get_env(:cryptocurrency, :gemini_api_key)
  @gemini_api_secret Application.get_env(:cryptocurrency, :gemini_api_secret)



  ################################################################################
  # Public API
  ################################################################################

  @doc """
  Fetches data from Gemini's public API. Forwards `headers` and `opts` to the `HTTPoison.get!/3`
  function.

  """
  @spec public_get(Path.t, keyword, keyword) :: HTTPoison.Response.t
  def public_get(endpoint, headers \\ [], opts \\ []) do
    url =
      Path.join(@base_url, endpoint)

    HTTPoison.get!(url, headers, opts)
  end


  @doc """
  Fetches data from Gemini's private API. Forwards `headers` and `opts` to the `HTTPoison.get!/3`
  function.

  """
  @spec private_get(Path.t, keyword, keyword) :: HTTPoison.Response.t
  def private_get(_endpoint, _headers, _opts) do
    raise("Not implemented")
  end


  @doc """
  Makes post requests to Gemini's API.

  """
  @spec post!(Path.t, keyword) :: HTTPoison.Response.t
  def post!(_endpoint, _opts) do
    raise("Not implemented")
  end


  @spec api_version :: binary
  def api_version,
    do: @api_version

end
