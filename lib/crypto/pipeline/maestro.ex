defmodule Crypto.Pipeline.Maestro do
  @moduledoc false

  use GenServer

  import ShorterMaps
  alias __MODULE__
  alias Crypto.Exchange.{GDAX, Kraken}

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
    task_gdax =
      Task.async(fn ->
        t0 =
          Timex.now |> Timex.to_unix

        ~M{bids, asks} =
          GDAX.fetch_order_book(:eth_usd)

        t1 =
          Timex.now |> Timex.to_unix

        {t1 - t0, {bids |> hd, asks |> hd}}
      end)

    task_kraken =
      Task.async(fn ->
        t0 =
          Timex.now |> Timex.to_unix

        ~M{bids, asks} =
          Kraken.fetch_order_book(:eth_usd)

        t1 =
          Timex.now |> Timex.to_unix

        {t1 - t0, {bids |> hd, asks |> hd}}
      end)

    {gdax_rtt, {%{price: gdax_bid}, %{price: gdax_ask}}} =
      Task.await(task_gdax)

    {kraken_rtt, {%{price: kraken_bid}, %{price: kraken_ask}}} =
      Task.await(task_kraken)

    kraken_to_gdax =
      gdax_bid - kraken_ask

    gdax_to_kraken =
      kraken_bid - gdax_ask

    # gdax buy: (1 + .0025), sell: (1 -.0025)
    # kraken buy: .0025, sell: .0025

    case {kraken_to_gdax > 0, gdax_to_kraken > 0} do
      {true, false} ->
        profit =
          compute_profit(buy: {Kraken, kraken_ask}, sell: {GDAX, gdax_bid})

        IO.puts("Kraken $#{kraken_ask} -> GDAX $#{gdax_bid}. Spread: $#{kraken_to_gdax}. Profit: $#{profit}")
{false, true} ->
        profit =
          compute_profit(buy: {GDAX, gdax_ask}, sell: {Kraken, kraken_bid})

        IO.puts("GDAX $#{gdax_ask} -> Kraken $#{kraken_bid}. Spread $#{gdax_to_kraken}. Profit: $#{profit}")

      {_, _} ->
        IO.puts("Hmmm... ")
    end

    updated_state =
      %{state |
        gdax_avg_round_trip: update_avg(state.gdax_avg_round_trip, gdax_rtt),
        kraken_avg_round_trip: update_avg(state.kraken_avg_round_trip, kraken_rtt),
       }

    log_averages(updated_state)

    {:reply, :ok, updated_state}
  end



  ################################################################################
  # Private Helpers
  ################################################################################

  @spec log_averages(state) :: :ok
  defp log_averages(%{kraken_avg_round_trip: kraken, gdax_avg_round_trip: gdax}) do
    IO.puts("Kraken RTT: #{compute_avg(kraken)}ms, GDAX RTT: #{compute_avg(gdax)}ms")
  end


  @spec update_avg(avg, new_time :: float) :: avg
  defp update_avg(~M{total_time, trip_count} = avg, new_time) do
    %{avg |
      total_time: total_time + new_time,
      trip_count: trip_count + 1
    }
  end


  @spec compute_avg(avg) :: float
  defp compute_avg(~M{total_time, trip_count}),
    do: total_time / trip_count


  @spec compute_profit(keyword) :: float
  defp compute_profit(opts) do
    {_exchange, buy} =
      Keyword.get(opts, :buy)

    {exchange, sell} =
      Keyword.get(opts, :sell)

    sell * (1 - apply(exchange, :transaction_fee, [])) -
    buy  * (1 + apply(exchange, :transaction_fee, []))
  end

end
