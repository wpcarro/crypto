defmodule Cryptocurrency.Pipeline.Maestro do
  @moduledoc """
  Module responsible for coordinating the Pipeline workers.

  The Maestro talks to the Matchmaker and the Quant and synthesizes the results from each.

  """

  use GenServer

  import ShorterMaps
  alias __MODULE__
  alias Cryptocurrency.Exchange.{GDAX, Bitfinex}
  alias Cryptocurrency.Pipeline.{Matchmaker, Quant}

  @cycle_interval 2_000
  @cycle_count 10



  ################################################################################
  # Constants
  ################################################################################

  @currency_pair :eth_usd
  @supported_exchanges [GDAX, Bitfinex]
  @pairable_exchanges Matchmaker.pairable_exchanges(@supported_exchanges)



  ################################################################################
  # Public API
  ################################################################################

  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end


  def rinse_repeat(cycles_remaining \\ @cycle_count)

  def rinse_repeat(0),
    do: :ok

  def rinse_repeat(cycles_remaining) do
    t0 =
      Timex.now |> Timex.to_unix

    task =
      Task.async(fn -> Maestro.cycle end)

    case Task.yield(task, @cycle_interval) || Task.shutdown(task) do
      {:ok, result} ->
        case result do
          {buy, sell, profit} ->
            spread =
              sell.price - buy.price

            print_fn =
              case profit > 0.0 do
                true  ->
                  fn msg -> [:green, msg] |> IO.ANSI.format |> IO.puts end

                false ->
                  fn msg -> [:red, msg] |> IO.ANSI.format |> IO.puts end
              end

            buy_total =
              buy.price * buy.volume

            sell_total =
              sell.price * sell.volume

            roi =
              profit / (buy_total + sell_total) |> Float.round(4)

            print_fn.("#{cycles_remaining}. #{stringify_exchange(buy.exchange)} $#{buy.price} X #{buy.volume} -> #{stringify_exchange(sell.exchange)} $#{sell.price} X #{sell.volume}")
            print_fn.("\t#{stringify_exchange(buy.exchange)} $#{buy_total} -> #{stringify_exchange(sell.exchange)} $#{sell_total}")
            print_fn.("\tSpread: $#{spread}")
            print_fn.("\tProfit: $#{profit}")
            print_fn.("\tROI: #{roi * 100}%\n")

          nil ->
            IO.puts("#{cycles_remaining} Holding...\n")
        end

      nil ->
        IO.inspect("Failed to get a result this cycle.")
        nil
    end

    t1 =
      Timex.now |> Timex.to_unix

    sleep_time =
      @cycle_interval - (t1 - t0)

    Process.sleep(sleep_time)
    Maestro.rinse_repeat(cycles_remaining - 1)
  end


  def cycle do
    GenServer.call(__MODULE__, {:cycle})
  end



  ################################################################################
  # GenServer Callbacks
  ################################################################################

  def init(:ok) do
    state =
      %{}

    {:ok, state}
  end


  def handle_call({:cycle}, _fr, state) do
    exchange_to_orderbook =
      @supported_exchanges
      |> Enum.map(&fetch_for_exchange/1)
      |> Task.yield_many(1_000)
      |> Enum.map(fn {task, res} ->
        case res do
          {:ok, {:ok, summary}} ->
            summary

          {:ok, {:error, :fetch_fail}} ->
            :fail

          nil ->
            # Task did not complete within time acceptable interval. Fail
            Task.shutdown(task, :brutal_kill)
            :fail

          {:exit, reason} ->
            # Task died. Fail
            IO.inspect("Task failed with reason: #{inspect(reason)}")
            :fail
        end
      end)
      |> Enum.reject(&match?(:fail, &1))
      |> Enum.into(%{})

    pairable_exchanges =
      @pairable_exchanges
      |> Enum.filter(fn {buy_exchange, sell_exchange} ->
        Map.has_key?(exchange_to_orderbook, buy_exchange) and
        Map.has_key?(exchange_to_orderbook, sell_exchange)
      end)

    case pairable_exchanges do
      [] -> IO.inspect("No pairable exchanges")
      _  -> :ok
    end

    result =
      pairable_exchanges
      |> Stream.map(fn {buy_exchange, sell_exchange} ->
        ~M{ask} =
          Map.fetch!(exchange_to_orderbook, buy_exchange)

        ~M{bid} =
          Map.fetch!(exchange_to_orderbook, sell_exchange)

        ask =
          %{price: ask.price, volume: ask.volume, exchange: buy_exchange}

        bid =
          %{price: bid.price, volume: bid.volume, exchange: sell_exchange}

        {ask, bid}
      end)
      |> Stream.map(fn {ask, bid} ->
        {buy_order, sell_order} =
          Quant.orders_for(asset_pair: @currency_pair, ask: ask, bid: bid)

        profit =
          Quant.arbitrage_profit(buy: buy_order, sell: sell_order)

        {buy_order, sell_order, profit}
      end)
      # |> Stream.reject(fn {_buy_order, _sell_order, profit} -> profit < 0.0 end)
      |> Enum.max_by(fn {_buy_order, _sell_order, profit} -> profit end, fn -> nil end)

    {:reply, result, state}
  end



  ################################################################################
  # Private Helpers
  ################################################################################

  @spec fetch_for_exchange(module) :: Task.t
  defp fetch_for_exchange(exchange) do
    Task.async(fn ->
      t0 =
        Timex.now |> Timex.to_unix

      result =
        apply(exchange, :fetch_order_book, [@currency_pair])

      t1 =
        Timex.now |> Timex.to_unix

      case result do
        ~M{bids, asks} ->
          key =
            exchange

          value =
            %{bid: bids |> List.first,
              ask: asks |> List.first,
              rtt: t1 - t0,
            }

          {:ok, {key, value}}

        _ -> {:error, :fetch_fail}
      end
    end)
  end


  @spec stringify_exchange(module) :: String.t
  defp stringify_exchange(exchange),
    do: Module.split(exchange) |> List.last

end
