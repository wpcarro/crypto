defmodule Crypto.Pipeline.Maestro do
  @moduledoc false

  use GenServer

  import ShorterMaps
  alias __MODULE__
  alias Crypto.Exchange.{GDAX, Gemini, Kraken, XBTCE}
  alias Crypto.Core.OrderBook
  alias Crypto.Pipeline.Quant

  @cycle_interval 3_000
  @cycle_count 10



  ################################################################################
  # Types
  ################################################################################

  @typep avg :: %{total_time: float, trip_count: non_neg_integer}

  @typep state :: %{
    total_profit: float,
    last_seen_profit: float,
  }



  ################################################################################
  # Constants
  ################################################################################

  @currency_pair :eth_usd
  @supported_exchanges [GDAX, Kraken, Gemini]



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
      Task.async(fn ->
        Maestro.run
      end)

    case Task.yield(task, @cycle_interval) || Task.shutdown(task) do
      {:ok, {buy, sell, profit, total_profit}} ->
        spread =
          sell.price - buy.price

        IO.puts("#{stringify_exchange(buy.exchange)} $#{buy.price} X #{buy.volume} -> #{stringify_exchange(sell.exchange)} $#{sell.price} X #{sell.volume}")
        IO.puts("\tSpread: $#{spread}")
        IO.puts("\tProfit: $#{profit}")
        IO.puts("\tTotal Profit: $#{total_profit}\n")

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


  def run do
    GenServer.call(__MODULE__, {:run})
  end



  ################################################################################
  # GenServer Callbacks
  ################################################################################

  def init(:ok) do
    state =
      %{total_profit: 0.0,
        last_seen_profit: nil,
       }

    {:ok, state}
  end


  def handle_call({:run}, _fr, state) do
    orders =
      @supported_exchanges
      |> Enum.map(&fetch_for_exchange/1)
      |> Task.yield_many(1_000)
      |> Enum.map(fn {task, {:ok, res}} ->
        case res do
          {:ok, summary} ->
            summary

          {:error, :fetch_fail} ->
            :fail

          nil ->
            Task.shutdown(task, :brutal_kill)
        end
      end)
      |> Enum.reject(&match?(:fail, &1))

    %{exchange: buy_exchange, ask: %{price: buy_price, volume: buy_volume}} =
      orders |> Enum.min_by(fn %{ask: ~M{price}} -> price end)

    %{exchange: sell_exchange, ask: %{price: sell_price, volume: sell_volume}} =
      orders |> Enum.max_by(fn %{bid: ~M{price}} -> price end)

    ask =
      %{price: buy_price, volume: buy_volume, exchange: buy_exchange}

    bid =
      %{price: sell_price, volume: sell_volume, exchange: sell_exchange}

    {buy, sell} =
      Quant.orders_for(ask: ask, bid: bid)

    profit =
      Quant.arbitrage_profit(buy: buy, sell: sell)

    updated_state =
      case state.last_seen_profit == profit do
        true ->
          %{state | last_seen_profit: profit}

        false ->
          %{state |
            total_profit: state.total_profit + profit,
            last_seen_profit: profit,
           }
      end

    result =
      {buy, sell, profit, updated_state.total_profit}

    {:reply, result, updated_state}
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
          summary =
            %{exchange: exchange,
              bid: bids |> hd,
              ask: asks |> hd,
              rtt: t1 - t0,
            }

          {:ok, summary}

        _ -> {:error, :fetch_fail}
      end
    end)
  end


  @spec compute_avg(avg) :: float
  defp compute_avg(~M{total_time, trip_count}),
    do: total_time / trip_count


  @spec stringify_exchange(module) :: String.t
  defp stringify_exchange(exchange),
    do: Module.split(exchange) |> List.last

end
