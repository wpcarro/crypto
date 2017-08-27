defmodule Cryptocurrency.Core.OrderBook do
  @moduledoc """
  Module defining the structured `OrderBook.t` for this application.

  """

  import ShorterMaps
  alias __MODULE__
  alias __MODULE__.Entry



  ################################################################################
  # Types
  ################################################################################

  @type entry_like :: map

  @type t :: %__MODULE__{
    bids: [Entry.t],
    asks: [Entry.t],
  }


  defstruct [
    asks: [],
    bids: []
  ]



  ################################################################################
  # Public API
  ################################################################################

  @doc """
  Convenience function for creating an `OrderBook.t`.

  Coerces bids and asks from entry-like shapes in `Entry.t` if need be.

  ## Options

    * `:bids` - `[entry_like | Entry.t]`. Specifies the order book entries for bids. Defaults to `[]`.

    * `:asks` - `[entry_like | Entry.t]`. Specifies the order book entries for asks. Defaults to `[]`.

  """
  @spec new(keyword) :: t
  def new(opts \\ []) do
    {bids, asks} =
      {Keyword.get(opts, :bids, [[]]), Keyword.get(opts, :asks, [[]])}

    bids =
      bids |> Enum.map(&struct!(Entry, &1))

    asks =
      asks |> Enum.map(&struct!(Entry, &1))

    ~M{%OrderBook bids, asks}
  end


  @doc """
  Finds the minimum number of orders from an order book than can fulfill the `demand` attempting to
  be sold, `:sell`, or bought, `:buy`.
  Reduces an order book of 50 entries into one that is capable to absorbing the `demand` of coins.

  """
  @spec orders_by_demand(t, keyword) :: [Entry.t]
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

  @spec fill_demand([Entry.t], float, [Entry.t]) :: [Entry.t]
  defp fill_demand([~M{%Entry volume} = order | rest], demand, acc) when demand > 0 do
    case demand - volume > 0 do
      true  -> fill_demand(rest, demand - volume, [order | acc])
      false -> :lists.reverse([order | acc])
    end
  end

end
