defmodule Cryptocurrency.Pipeline.Maestro do
  @moduledoc """
  Module responsible for coordinating the Pipeline workers.

  The Maestro talks to the Matchmaker and the Quant and synthesizes the results from each.

  """

  use GenServer

  import ShorterMaps
  alias __MODULE__
  alias Cryptocurrency.Exchange.{GDAX, Bitfinex, Kraken}
  alias Cryptocurrency.Pipeline.{Matchmaker, Quant}



  ################################################################################
  # Types
  ################################################################################

  @typep exchange :: module
  @typep round_trip_time :: non_neg_integer
  @typep buy :: Order.t
  @typep sell :: Order.t
  @typep profit :: float



  ################################################################################
  # Constants
  ################################################################################

  @currency_pair :eth_usd
  @supported_exchanges [GDAX, Bitfinex, Kraken]
  @pairable_exchanges Matchmaker.pairable_exchanges(@supported_exchanges)
  @cycle_interval 2_000
  @default_cycle_count 10



  ################################################################################
  # Public API
  ################################################################################

  @spec start_link :: GenServer.on_start
  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end


  @doc """
  Repeatedly searches for maximum profit opportunities between exchanges until `cycle_count` is
  exhausted.

  """
  @spec rinse_repeat(non_neg_integer | :infinite) :: :ok
  def rinse_repeat(cycle_count \\ @default_cycle_count)

  def rinse_repeat(:infinite) do
    t0 =
      Timex.now |> Timex.to_unix

    :ok = do_rinse_repeat()

    t1 =
      Timex.now |> Timex.to_unix

    sleep_time =
      @cycle_interval - (t1 - t0)

    Process.sleep(sleep_time)
    Maestro.rinse_repeat(:infinite)
  end

  def rinse_repeat(0),
    do: :ok

  def rinse_repeat(cycle_count) do
    t0 =
      Timex.now |> Timex.to_unix

    :ok = do_rinse_repeat(cycle_count)

    t1 =
      Timex.now |> Timex.to_unix

    sleep_time =
      @cycle_interval - (t1 - t0)

    Process.sleep(sleep_time)
    Maestro.rinse_repeat(cycle_count - 1)
  end


  @spec do_rinse_repeat(non_neg_integer) :: :ok
  defp do_rinse_repeat(cycle_count \\ 1) do
    task =
      Task.async(&find_arbitrage_opportunity/0)

    case Task.yield(task, @cycle_interval) || Task.shutdown(task) do
      {:ok, result} ->
        case result do
          {buy, sell, profit} ->
            spread =
              sell.price - buy.price

            color =
              case profit > 0.0 do
                true  -> :green
                false -> :red
              end

            logging_fn =
              colorized_logger(color)

            {buy_total, sell_total} =
              {buy.price * buy.volume, sell.price * sell.volume}

            roi =
              profit / (buy_total + sell_total) |> Float.round(4)

            logging_fn.("#{cycle_count}. #{stringify_exchange(buy.exchange)} $#{buy.price} X #{buy.volume} -> #{stringify_exchange(sell.exchange)} $#{sell.price} X #{sell.volume}")
            logging_fn.("\t#{stringify_exchange(buy.exchange)} $#{buy_total} -> #{stringify_exchange(sell.exchange)} $#{sell_total}")
            logging_fn.("\tSpread: $#{spread}")
            logging_fn.("\tProfit: $#{profit}")
            logging_fn.("\tROI: #{roi * 100}%\n")

          nil ->
            IO.puts("#{cycle_count} Holding...\n")
        end

      nil ->
        IO.inspect("Failed to get a result this cycle.")
        nil
    end
  end


  @doc """
  Finds the maximum profit opportunity for all pairable exchanges.

  Returns a buy order, a sell order, and profit (accounting for transaction fees).

  """
  @spec find_arbitrage_opportunity :: {buy, sell, profit} | nil
  def find_arbitrage_opportunity do
    GenServer.call(__MODULE__, {:find_arbitrage_opportunity})
  end



  ################################################################################
  # GenServer Callbacks
  ################################################################################

  @impl GenServer
  def init(:ok) do
    state =
      %{}

    {:ok, state}
  end


  @impl GenServer
  def handle_call({:find_arbitrage_opportunity}, _fr, state) do
    exchange_to_orderbook =
      @supported_exchanges |> orderbooks_for()

    pairable_exchanges =
      @pairable_exchanges
      |> Enum.filter(fn {buy_exchange, sell_exchange} ->
        Map.has_key?(exchange_to_orderbook, buy_exchange) and
        Map.has_key?(exchange_to_orderbook, sell_exchange)
      end)

    result =
      case pairable_exchanges do
        [] ->
          IO.inspect("No pairable exchanges")
          nil

        _ ->
          IO.inspect(pairable_exchanges)
          Quant.max_profit_for(pairable_exchanges, exchange_to_orderbook,
            currency_pair: @currency_pair, reject_negative_profits: false)
      end

    {:reply, result, state}
  end



  ################################################################################
  # Private Helpers
  ################################################################################

  @doc """
  Fetches all of the `OrderBook.t` for each of the `exchanges`.

  Each orderbook is tagged with the time it took the HTTP request took to be sent to and from the
  exchange.

  """
  @spec orderbooks_for([exchange]) :: %{required(exchange) => {round_trip_time, OrderBook.t}}
  def orderbooks_for(exchanges) do
    exchanges
    |> Enum.map(&Task.async(fn -> orderbook_for(&1) end))
    |> Task.yield_many(1_000)
    |> Enum.map(fn {task, res} ->
      case res do
        {:ok, {:ok, {_rtt, _orderbook} = summary}} ->
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
  end



  ################################################################################
  # Private Helpers
  ################################################################################

  @spec orderbook_for(exchange) :: {:ok, result} | {:error, :fetch_fail}
        when result: {exchange, {round_trip_time, OrderBook.t}}
  defp orderbook_for(exchange) do
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
  end


  @spec stringify_exchange(module) :: String.t
  defp stringify_exchange(exchange),
    do: Module.split(exchange) |> List.last


  @spec colorized_logger(atom) :: (any -> :ok)
  defp colorized_logger(color),
    do: fn msg -> [color, msg] |> IO.ANSI.format |> IO.puts end


end
