defmodule Cryptocurrency.Core.OrderBookTest do
  use ExUnit.Case, async: true

  import ShorterMaps
  alias Cryptocurrency.Core.OrderBook

  setup do
    book =
      %OrderBook{
        asks: [
          %{order_count: 5, price: 275.79, volume: 7.14299648},
          %{order_count: 1, price: 275.8,  volume: 0.01},
          %{order_count: 2, price: 275.82, volume: 4.12},
        ],
        bids: [
          %{order_count: 4, price: 275.78, volume: 2.49953577},
          %{order_count: 1, price: 275.77, volume: 4.262},
          %{order_count: 1, price: 275.75, volume: 0.25},
        ]
      }

    {:ok, ~M{book}}
  end

  describe "orders_by_demand/2" do
    test "works for selling coins", ~M{book} do
      assert OrderBook.orders_by_demand(book, sell: 1) == [
        %{order_count: 4, price: 275.78, volume: 2.49953577},
      ]

      assert OrderBook.orders_by_demand(book, sell: 5.5) == [
        %{order_count: 4, price: 275.78, volume: 2.49953577},
        %{order_count: 1, price: 275.77, volume: 4.262},
      ]
    end

    test "works for buying coins", ~M{book} do
      assert OrderBook.orders_by_demand(book, buy: 2.2) == [
        %{order_count: 5, price: 275.79, volume: 7.14299648},
      ]

      assert OrderBook.orders_by_demand(book, buy: 10) == [
        %{order_count: 5, price: 275.79, volume: 7.14299648},
        %{order_count: 1, price: 275.8, volume: 0.01},
        %{order_count: 2, price: 275.82, volume: 4.12},
      ]
    end
  end

end
