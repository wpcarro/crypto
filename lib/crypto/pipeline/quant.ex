defmodule Cryptocurrency.Pipeline.Quant do
  @moduledoc false

  import ShorterMaps
  alias Cryptocurrency.Core.{Order, OrderBook}



  ################################################################################
  # Public API
  ################################################################################

  @doc """
  Receives a list of tuples representing buy and sell exchange pairings and returns the pair with
  the largest profit opportunity.

  ## Options

    * `:currency_pair` - `Exchange.asset_pair`. Required.

    * `:reject_negative_profits` - `boolean`. Returns an empty list of none of the opportunities are
      profitable. Defaults to true.

  """
  @spec max_profit_for([{buy_exchange, sell_exchange}], %{exchange => OrderBook.t}, keyword) :: {buy, sell, profit} when
        buy_exchange: module, sell_exchange: module, exchange: module,
        buy: Order.t, sell: Order.t, profit: float
  def max_profit_for(pairable_exchanges, exchange_to_orderbook, opts \\ []) do
    currency_pair =
      Keyword.fetch!(opts, :currency_pair)

    reject_negative_profits? =
      Keyword.get(opts, :reject_negative_profits, true)

    rejection_predicate =
      case reject_negative_profits? do
        true  -> fn {_buy_order, _sell_order, profit} -> profit < 0.0 end
        false -> fn _ -> false end
      end

    pairable_exchanges
    |> Stream.map(fn {buy_exchange, sell_exchange} ->
      ~M{ask} =
        Map.fetch!(exchange_to_orderbook, buy_exchange)

      ~M{bid} =
        Map.fetch!(exchange_to_orderbook, sell_exchange)

      # {bid, ask} =
      #   {hd(bids), hd(asks)}

      # ask =
      #   %{price: ask.price, volume: ask.volume, exchange: buy_exchange}

      # bid =
      #   %{price: bid.price, volume: bid.volume, exchange: sell_exchange}

      {buy_order, sell_order} =
        orders_for(asset_pair: currency_pair, ask: ask, bid: bid)

      profit =
        arbitrage_profit(buy: buy_order, sell: sell_order)

      {buy_order, sell_order, profit}
    end)
    |> Stream.reject(rejection_predicate)
    |> Enum.max_by(fn {_buy_order, _sell_order, profit} -> profit end, fn -> nil end)
  end


  @doc """
  Computes the realizable profit for a particular arbitrage opportunity.

  The arbitrage profit depends on a series of fees that vary between each exchange and depend on the
  arbitrage strategy.

  ## Fees

    * Exchange transaction fees, which are a function of the `:asset_pair` being transacted.

    * Exchange withdrawal fees, which may vary for different `:asset_pair`.

  ## Fees (Not Implemented)

    * Exchange margin trading fees (if applicable).

  ## Options

    * `:buy` - `Order.t`. The buy order.

    * `:sell` - `Order.t`. The sell order.

  """
  @spec arbitrage_profit(keyword) :: float
  def arbitrage_profit(opts \\ []) do
    %Order{
      side: :buy,
      exchange: buy_exchange,
      asset_pair: buy_asset,
      volume: buy_volume,
      price: buy_price,
    } = Keyword.fetch!(opts, :buy)

    %Order{
      side: :sell,
      exchange: sell_exchange,
      asset_pair: sell_asset,
      volume: sell_volume,
      price: sell_price,
    } = Keyword.fetch!(opts, :sell)

    # Transaction fees
    buy_tx_fee =
      apply(buy_exchange, :transaction_fee, [buy_asset])

    sell_tx_fee =
      apply(sell_exchange, :transaction_fee, [sell_asset])

    # Withdrawal fee
    withdrawal_fee =
      apply(buy_exchange, :withdrawal_fee, [buy_asset])

    to_buy =
      buy_price * buy_volume * (1 + buy_tx_fee) + withdrawal_fee

    to_sell =
      sell_price * sell_volume * (1 - sell_tx_fee)

    to_sell - to_buy
  end


  @doc """
  Creates orders for a particular `:bid` and `:ask`.

  ## Options

    * `:bid` - `map`. Contains `:price`, `:volume`, and `:exchange` data about the buy order.

    * `:ask` - `map`. Contains `:price`, `:volume`, and `:exchange` data about the sell order.

    * `:asset_pair` - `Exchange.asset_pair`. An atom denoting the bid and sell assets for the
      desired order.

    * `:max_volume` - `float`. The maximum volume allowed regardless of the opportunity size.

  """
  @spec orders_for(keyword) :: {buy :: map, sell :: map}
  def orders_for(opts \\ []) do
    asset_pair =
      Keyword.fetch!(opts, :asset_pair)

    %{price: buy_price, volume: buy_volume, exchange: buy_exchange} =
      Keyword.fetch!(opts, :ask)

    %{price: sell_price, volume: sell_volume, exchange: sell_exchange} =
      Keyword.fetch!(opts, :bid)

    max_volume =
      Keyword.get(opts, :max_volume, :no_limit)

    volume =
      case max_volume do
        :no_limit -> min(buy_volume, sell_volume)
        limit     -> min(buy_volume, sell_volume) |> min(limit)
      end

    buy =
      %Order{
        side: :buy,
        exchange: buy_exchange,
        price: buy_price,
        volume: volume,
        asset_pair: asset_pair,
      }

    sell =
      %Order{
        side: :sell,
        exchange: sell_exchange,
        price: sell_price,
        volume: volume,
        asset_pair: asset_pair,
      }

    {buy, sell}
  end

end
