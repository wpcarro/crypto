defmodule Crypto.Pipeline.PoolTest do
  use ExUnit.Case, async: true

  import ShorterMaps
  alias Crypto.Pipeline.Pool
  alias Crypto.Exchange.{GDAX, Gemini, Kraken, Poloniex, XBTCE}

  defmodule MockExchange do
    def __using__(opts \\ []) do
      quote do
        def fetch_order_book(_), do: :ok
        def transaction_fee(_), do: :ok
        def withdrawal_fee(_), do: :ok
        def execute_orders(_), do: :ok
        def supported_assets, do: :ok
      end
    end
  end


  defmodule A do
    use MockExchange
    def supported_assets, do: MapSet.new([:eth, :btc, :usd])
  end

  defmodule B do
    use MockExchange
    def supported_assets, do: MapSet.new([:btc, :usd])
  end

  defmodule C do
    use MockExchange
    def supported_assets, do: MapSet.new([:eth, :ltc, :btc, :usd])
  end

  defmodule D do
    use MockExchange
    def supported_assets, do: MapSet.new([:pizza, :coffee, :butter])
  end


  describe "matchmake/1" do
    test "works with two exchanges with shared currencies" do
      exchanges =
        [A, C]

      [~M{shared_assets, exchanges}] =
        Pool.matchmake(exchanges)

      assert MapSet.member?(shared_assets, :eth)
      assert MapSet.member?(shared_assets, :btc)
      assert MapSet.member?(shared_assets, :usd)

      refute MapSet.member?(shared_assets, :ltc)

      assert MapSet.member?(exchanges, A)
      assert MapSet.member?(exchanges, C)
    end

    test "works with two exchanges with no shared currencies" do
      exchanges =
        [A, D]

      [~M{shared_assets, exchanges}] =
        Pool.matchmake(exchanges)

      assert Enum.count(shared_assets) == 0
      assert Enum.count(exchanges) == 0
    end

    test "works with three exchanges" do
      exchanges =
        [A, B, C]

      pools =
        Pool.matchmake(exchanges)
    end
  end

end
