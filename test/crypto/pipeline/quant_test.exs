defmodule Crypto.Pipeline.QuantTest do
  use ExUnit.Case, async: true

  alias Crypto.Core.Order
  alias Crypto.Exchange.{GDAX, Gemini}
  alias Crypto.Pipeline.Quant

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

      assert Quant.orders_for(ask: ask, bid: bid) == {
        %Order{exchange: Gemini, side: :buy, price: 241.13, volume: 4.0},
        %Order{exchange: GDAX, side: :sell, price: 242.50, volume: 4.0}
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

      assert Quant.orders_for(ask: ask, bid: bid) == {
        %Order{exchange: Gemini, side: :buy, price: 241.13, volume: 4.0},
        %Order{exchange: GDAX, side: :sell, price: 242.50, volume: 4.0}
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

      assert Quant.orders_for(ask: ask, bid: bid) == {
        %Order{exchange: Gemini, side: :buy, price: 241.13, volume: 10.0},
        %Order{exchange: GDAX, side: :sell, price: 242.50, volume: 10.0}
      }
    end
  end


  describe "arbitrage_profit/1" do
    test "works for one order" do
      buy =
        %Order{exchange: GDAX, side: :buy, price: 241.13, volume: 1.0, asset: :eth}

      sell =
        %Order{exchange: GDAX, side: :sell, price: 245.13, volume: 1.0, asset: :eth}

      assert Quant.arbitrage_profit(buy: buy, sell: sell) |> Float.round(2) == 2.54
    end
  end

end
