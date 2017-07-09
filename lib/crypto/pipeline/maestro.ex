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
    kraken_avg_round_trip: avg,
    gdax_avg_round_trip: avg,
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
    Maestro.run
    Process.sleep(@cycle_interval)
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
      %{kraken_avg_round_trip: %{total_time: 0, trip_count: 0},
        gdax_avg_round_trip: %{total_time: 0, trip_count: 0},
       }

    {:ok, state}
  end


  def handle_call({:run}, _fr, state) do
    orders =
      @supported_exchanges
      |> Enum.map(&fetch_for_exchange/1)
      |> Task.yield_many(1_000)
      |> Enum.map(fn {task, {:ok, res}} ->
        res || Task.shutdown(task, :brutal_kill)
      end)

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

    spread =
      sell_price - buy_price

    profit =
      Quant.arbitrage_profit([buy, sell])

    IO.puts("#{buy_exchange} $#{buy_price} -> #{sell_exchange} $#{sell_price}")
    IO.puts("\tSpread: $#{spread}")
    IO.puts("\tProfit: $#{profit}\n")

    {:reply, :ok, state}
  end



  ################################################################################
  # Private Helpers
  ################################################################################

  @spec fetch_for_exchange(module) :: Task.t
  defp fetch_for_exchange(exchange) do
    Task.async(fn ->
      t0 =
        Timex.now |> Timex.to_unix

      ~M{bids, asks} =
        apply(exchange, :fetch_order_book, [@currency_pair])


      t1 =
        Timex.now |> Timex.to_unix

      %{exchange: exchange,
        bid: bids |> hd,
        ask: asks |> hd,
        rtt: t1 - t0,
      }
    end)
  end


  @spec compute_avg(avg) :: float
  defp compute_avg(~M{total_time, trip_count}),
    do: total_time / trip_count

end
