defmodule Cryptocurrency.Exchange.XBTCE do
  @moduledoc """
  Behaviour module implementing the `Cryptocurrency.Exchange` callbacks for the xBTCe exchange.

  """

  alias Cryptocurrency.Exchange.XBTCE.HTTP

  @behaviour Cryptocurrency.Exchange



  ################################################################################
  # Callback Definitions
  ################################################################################

  def fetch_order_book(asset_pair) do
    asset_pair =
      to_asset_pair(asset_pair)

    HTTP.public_get("level2/#{asset_pair}")
  end


  def transaction_fee(_),
    do: raise("Not implemented.")


  def execute_orders(_order),
    do: raise("Not implemented.")


  def supported_assets,
    do: raise("Not implemented.")


  def supported_sides,
    do: raise("Not implemented.")



  ################################################################################
  # Private Helpers
  ################################################################################

  defp to_asset_pair(:eth_usd), do: "eth%20usd"
  defp to_asset_pair(:ltc_usd), do: "ltc%20usd"
end
