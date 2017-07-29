defmodule Cryptocurrency.Pipeline.MatchmakerTest do
  use ExUnit.Case, async: true

  alias Cryptocurrency.Pipeline.Matchmaker


  describe "get_pairable_exchanges/0" do
    test "excludes same-exchange pairings" do
      buy_exchanges =
        [:a, :b]

      sell_exchanges =
        [:a, :b]

      pairings =
        Matchmaker.pairable_exchanges(buy: buy_exchanges, sell: sell_exchanges)

      refute Enum.member?(pairings, {:a, :a})
      refute Enum.member?(pairings, {:b, :b})
    end
  end
end
