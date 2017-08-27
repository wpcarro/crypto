defmodule Cryptocurrency.Pipeline.MatchmakerTest do
  use ExUnit.Case, async: true

  import ShorterMaps
  alias Cryptocurrency.Pipeline.Matchmaker


  defmodule A do
    use MockExchange, supported_sides: [:buy, :sell]
  end

  defmodule B do
    use MockExchange, supported_sides: [:buy, :sell]
  end

  defmodule C do
    use MockExchange, supported_sides: []
  end

  defmodule D do
    use MockExchange, supported_sides: [:sell]
  end


  describe "matchmake/1" do
    setup do
      exchanges =
        [A, B, C, D]

      pairs =
        Matchmaker.pairable_exchanges(exchanges)

      {:ok, ~M{pairs}}
    end

    test "does not pair any exchange with itself", ~M{pairs} do
      refute Enum.member?(pairs, {A, A})
      refute Enum.member?(pairs, {B, B})
      refute Enum.member?(pairs, {C, C})
      refute Enum.member?(pairs, {D, D})
    end

    test "pairs all buy exchanges with all sell exchanges", ~M{pairs} do
      assert Enum.member?(pairs, {A, B})
      assert Enum.member?(pairs, {B, A})

      assert Enum.member?(pairs, {A, D})
      assert Enum.member?(pairs, {B, D})
    end

    test "does not allow for sell-only exchanges to appear as buy exchanges", ~M{pairs} do
      # since D cannot sell, it should never appear on the LHS of any tuple
      refute Enum.member?(pairs, {D, A})
      refute Enum.member?(pairs, {D, B})
      refute Enum.member?(pairs, {D, C})
    end

    test "does not pair exchange C with any exchange", ~M{pairs} do
      # C cannot pair with any other exchange since it supports neither side
      refute Enum.member?(pairs, {C, A})
      refute Enum.member?(pairs, {C, B})
      refute Enum.member?(pairs, {C, D})
    end
  end
end
