defmodule Crypto.Pipeline.Quant do
  @moduledoc false

  import ShorterMaps
  alias Crypto.Core.Order



  ################################################################################
  # Public API
  ################################################################################

  @max_coin_position 100



  ################################################################################
  # Public API
  ################################################################################

  @doc """
  Receives `:ask` and `:bid` information and creates both a buy and sell order that represents the
  optimal acceptable action given the ask and bid data.

  Returns a tuple of `{buy, sell}` where both `buy` and `sell` are `Order.t`.

  """
  @spec orders_for(keyword) :: {buy :: Order.t, sell :: Order.t}
  def orders_for(opts \\ []) do
    asset_pair =
      Keyword.fetch!(opts, :asset_pair)

    %{price: buy_price, volume: buy_volume, exchange: buy_exchange} =
      Keyword.fetch!(opts, :ask)

    %{price: sell_price, volume: sell_volume, exchange: sell_exchange} =
      Keyword.fetch!(opts, :bid)

    volume =
      min(buy_volume, sell_volume) |> min(@max_coin_position)

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


  @doc """
  Given a list of `Order.t` compute the expected profit after exchange transaction fees apply.

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

end
