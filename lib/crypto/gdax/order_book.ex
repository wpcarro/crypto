defmodule Crypto.GDAX.OrderBook do
  @moduledoc """
  Module defining the structured order book data from GDAX.

  """

  import ShorterMaps
  alias __MODULE__

  defstruct [
    asks: [],
    bids: []
  ]



  ################################################################################
  # Types
  ################################################################################

  @typep order :: %{price: float, size: float, order_count: pos_integer}
  @type t :: %__MODULE__{
    asks: [order],
    bids: [order],
  }



  ################################################################################
  # Public API
  ################################################################################

  @doc """
  """
  @spec from_raw(map) :: t
  def from_raw(raw) do
    %{"asks" => asks, "bids" => bids} =
      raw

    decode_entry = fn
      [price, size, order_count] ->
        %{price: parse_float(price),
          size: parse_float(size),
          order_count: order_count,
         }
    end

    struct(OrderBook, asks: Enum.map(asks, decode_entry), bids: Enum.map(bids, decode_entry))
  end


  @doc """
  Finds the minimum number of orders from an order book than can fulfill the `demand` attempting to
  be sold, `:sell`, or bought, `:buy`.
  Reduces an order book of 50 entries into one that is capable to absorbing the `demand` of coins.

  """
  @spec orders_by_demand(t, keyword) :: t
  def orders_by_demand(~M{%OrderBook asks, bids}, opts) do
    struct_cfg =
      case {Keyword.get(opts, :buy), Keyword.get(opts, :sell)} do
        {buy_amt, nil} ->
          [bids: [], asks: fill_demand(asks, buy_amt)]

        {nil, sell_amt} ->
          [bids: fill_demand(bids, sell_amt), asks: []]
      end

    struct(OrderBook, struct_cfg)
  end



  ################################################################################
  # Private Helpers
  ################################################################################

  @spec fill_demand([order], float) :: [order]
  defp fill_demand(list, demand) do
    do_fill_demand(list, demand, [])
  end

  @spec do_fill_demand([order], float, [order]) :: [order]
  defp do_fill_demand([~M{size} = order | rest], demand, acc) when demand > 0 do
    case demand - size > 0 do
      true  -> do_fill_demand(rest, demand - size, [order | acc])
      false -> :lists.reverse([order | acc])
    end
  end

  @spec parse_float(binary) :: float
  defp parse_float(input) do
    {result, ""} =
      Float.parse(input)

    result
  end

end
