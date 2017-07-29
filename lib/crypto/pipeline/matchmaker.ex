defmodule Cryptocurrency.Pipeline.Matchmaker do
  @moduledoc """
  Module responsible for pairing compatible buy and sell exchanges.

  Future plans include determining compatibility based off of the assets that they can exchange.

  """

  alias Cryptocurrency.Core.Order



  ################################################################################
  # Public API
  ################################################################################

  @doc """
  Pairs cryptocurrency exchanges together based on their compatibility. Certain exchanges are
  classified as buy-only or sell-only or buy-and-sell. Because of this, we need to compute a list at
  compile-time that contains only compatible exchange pairs.

  """
  @spec pairable_exchanges([exchange]) :: [{buy_exchange, sell_exchange}] when
        exchange: module,
        buy_exchange: module,
        sell_exchange: module
  def pairable_exchanges(exchanges) do
    buy_exchanges =
      exchanges |> filter_by_side(:buy)

    sell_exchanges =
      exchanges |> filter_by_side(:sell)

    for buy <- buy_exchanges, sell <- sell_exchanges do
      {buy, sell}
    end
    |> Enum.reject(fn {buy, sell} -> buy == sell end)
  end



  ################################################################################
  # Private API
  ################################################################################

  @spec filter_by_side([exchange], Order.side) :: [exchange] when exchange: module
  defp filter_by_side(exchanges, side) do
    exchanges
    |> Enum.filter(fn exchange ->
      supported_sides =
        apply(exchange, :supported_sides, [])

      MapSet.member?(supported_sides, side)
    end)
  end

end
