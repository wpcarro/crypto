defmodule Cryptocurrency.Core.OrderBook do
  @moduledoc """
  Module defining the structured `OrderBook.t` for this application.

  """

  import ShorterMaps
  alias __MODULE__



  ################################################################################
  # Types
  ################################################################################

  @type price_level :: %{price: float, volume: float, extra: map}

  @type t :: %__MODULE__{
    bids: [price_level],
    asks: [price_level],
  }


  defstruct [
    asks: [],
    bids: []
  ]



  ################################################################################
  # Public API
  ################################################################################

  @doc """
  Finds the minimum number of orders from an order book than can fulfill the `demand` attempting to
  be sold, `:sell`, or bought, `:buy`.
  Reduces an order book of 50 entries into one that is capable to absorbing the `demand` of coins.

  """
  @spec orders_by_demand(t, keyword) :: [price_level]
  def orders_by_demand(~M{%OrderBook asks, bids}, opts) do
    case {Keyword.get(opts, :buy), Keyword.get(opts, :sell)} do
      {buy_amt, nil} ->
        fill_demand(asks, buy_amt, [])

      {nil, sell_amt} ->
        fill_demand(bids, sell_amt, [])
    end
  end



  ################################################################################
  # Private Helpers
  ################################################################################

  @spec fill_demand([price_level], float, [price_level]) :: [price_level]
  defp fill_demand([~M{volume} = order | rest], demand, acc) when demand > 0 do
    case demand - volume > 0 do
      true  -> fill_demand(rest, demand - volume, [order | acc])
      false -> :lists.reverse([order | acc])
    end
  end

end
