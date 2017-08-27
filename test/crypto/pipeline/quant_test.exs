defmodule Cryptocurrency.Pipeline.QuantTest do
  use ExUnit.Case, async: true

  alias Cryptocurrency.Core.{Order, OrderBook}
  alias Cryptocurrency.Exchange.{GDAX, Gemini}
  alias Cryptocurrency.Pipeline.Quant


  defmodule BuyA do
    use MockExchange
  end

  defmodule BuyB do
    use MockExchange
  end

  defmodule SellA do
    use MockExchange
  end


  describe "max_profit_for/2" do
    test "chooses the pairable exchange with the greatest profit" do
      pairable_exchanges =
        [{BuyA, SellA}, {BuyB, SellA}]

      exchange_to_orderbook =
        %{
          # selling opportunity is at 11.50
          SellA => OrderBook.new(bids: [[price: 11.50, volume: 1.0]]),

          # buy @ 10.51 sell @ 11.50
          BuyA => OrderBook.new(asks: [[price: 10.51, volume: 1.0]]),
          # buy @ 9.51 sell @ 11.50
          BuyB => OrderBook.new(asks: [[price: 9.51, volume: 1.0]]),
         }

      result =
        Quant.max_profit_for(pairable_exchanges, exchange_to_orderbook, currency_pair: :eth_usd)

      buy =
        %Order{
          side: :buy,
          price: 9.51,
          volume: 1.0,
          exchange: BuyB,
          asset_pair: :eth_usd,
        }

      sell =
        %Order{
          side: :sell,
          price: 11.50,
          volume: 1.0,
          exchange: SellA,
          asset_pair: :eth_usd,
        }

      assert {^buy, ^sell, _profit} = result
    end

    test "returns nil when all of the opportunities are non-profitable" do
      pairable_exchanges =
        [{BuyA, SellA}]

      exchange_to_orderbook =
        %{
          # selling opportunity is at 11.49
          SellA => OrderBook.new(bids: [[price: 11.49, volume: 1.0]]),

          # buy @ 11.50 sell @ 11.50
          BuyA => OrderBook.new(asks: [[price: 11.50, volume: 1.0]]),
         }

      result =
        Quant.max_profit_for(pairable_exchanges, exchange_to_orderbook, currency_pair: :eth_usd,
          reject_negative_profits: true)

      assert result == nil
    end
  end


  describe "orders_for" do
    test "generates the buy and sell orders given a particular bid and ask" do
      ask =
        %{exchange: Gemini,
          price: 241.13,
          volume: 98.793,
        }

      bid =
        %{exchange: GDAX,
          price: 242.50,
          volume: 4.0,
         }

      assert Quant.orders_for(ask: ask, bid: bid, asset_pair: :btc_usd) == {
        %Order{exchange: Gemini, side: :buy, price: 241.13, volume: 4.0, asset_pair: :btc_usd},
        %Order{exchange: GDAX, side: :sell, price: 242.50, volume: 4.0, asset_pair: :btc_usd}
      }

      ask =
        %{exchange: Gemini,
          price: 241.13,
          volume: 4.0,
        }

      bid =
        %{exchange: GDAX,
          price: 242.50,
          volume: 98.793,
         }

      assert Quant.orders_for(ask: ask, bid: bid, asset_pair: :eth_usd) == {
        %Order{exchange: Gemini, side: :buy, price: 241.13, volume: 4.0, asset_pair: :eth_usd},
        %Order{exchange: GDAX, side: :sell, price: 242.50, volume: 4.0, asset_pair: :eth_usd}
      }
    end

    test "limits buy / sell volume by the maximum acceptable coin position" do
      ask =
        %{exchange: Gemini,
          price: 241.13,
          volume: 98.793,
        }

      bid =
        %{exchange: GDAX,
          price: 242.50,
          volume: 90.500,
         }

      assert Quant.orders_for(ask: ask, bid: bid, asset_pair: :eth_usd, max_volume: 10.0) == {
        %Order{exchange: Gemini, side: :buy, price: 241.13, volume: 10.0, asset_pair: :eth_usd},
        %Order{exchange: GDAX, side: :sell, price: 242.50, volume: 10.0, asset_pair: :eth_usd}
      }
    end

    test "does not limit buy / sell volume when max_volume is unset" do
      ask =
        %{exchange: Gemini,
          price: 241.13,
          volume: 98.793,
        }

      bid =
        %{exchange: GDAX,
          price: 242.50,
          volume: 90.500,
         }

      assert Quant.orders_for(ask: ask, bid: bid, asset_pair: :eth_usd) == {
        %Order{exchange: Gemini, side: :buy, price: 241.13, volume: 90.5, asset_pair: :eth_usd},
        %Order{exchange: GDAX, side: :sell, price: 242.50, volume: 90.5, asset_pair: :eth_usd}
      }
    end
  end


  describe "arbitrage_profit/1" do
    test "works for one order" do
      buy =
        %Order{exchange: GDAX, side: :buy, price: 241.13, volume: 1.0, asset_pair: :eth_usd}

      sell =
        %Order{exchange: GDAX, side: :sell, price: 245.13, volume: 1.0, asset_pair: :eth_usd}

      assert Quant.arbitrage_profit(buy: buy, sell: sell) |> Float.round(2) == 2.54
    end

    test "assesses transaction fees"
    test "assesses withdrawal fees"
    test "assesses margin trading fees"
  end

end
