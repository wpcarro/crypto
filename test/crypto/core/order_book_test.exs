defmodule Cryptocurrency.Core.OrderBookTest do
  use ExUnit.Case, async: true

  import ShorterMaps
  alias Cryptocurrency.Core.OrderBook
  alias Cryptocurrency.Core.OrderBook.Entry

  setup do
    book =
      %OrderBook{
        asks: [
          %Entry{price: 275.79, volume: 7.14299648},
          %Entry{price: 275.8,  volume: 0.01},
          %Entry{price: 275.82, volume: 4.12},
        ],
        bids: [
          %Entry{price: 275.78, volume: 2.49953577},
          %Entry{price: 275.77, volume: 4.262},
          %Entry{price: 275.75, volume: 0.25},
        ]
      }

    {:ok, ~M{book}}
  end

  describe "orders_by_demand/2" do
    test "works for selling coins", ~M{book} do
      assert OrderBook.orders_by_demand(book, sell: 1) == [
        %Entry{price: 275.78, volume: 2.49953577},
      ]

      assert OrderBook.orders_by_demand(book, sell: 5.5) == [
        %Entry{price: 275.78, volume: 2.49953577},
        %Entry{price: 275.77, volume: 4.262},
      ]
    end

    test "works for buying coins", ~M{book} do
      assert OrderBook.orders_by_demand(book, buy: 2.2) == [
        %Entry{price: 275.79, volume: 7.14299648},
      ]

      assert OrderBook.orders_by_demand(book, buy: 10) == [
        %Entry{price: 275.79, volume: 7.14299648},
        %Entry{price: 275.8, volume: 0.01},
        %Entry{price: 275.82, volume: 4.12},
      ]
    end
  end

end
