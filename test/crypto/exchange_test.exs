defmodule Cryptocurrency.ExchangeTest do
  use ExUnit.Case, async: true

  alias Cryptocurrency.Exchange

  defmodule DefaultExchange do
    use Exchange
  end

  defmodule ConfiguredExchange do
    use Exchange,
      supported_assets: [:btc, :eth, :usd],
      supported_sides: [:buy],
      transaction_fee: [btc_usd: 0.025, eth_usd: 0.05],
      withdrawal_fee: [btc_usd: 0.075, eth_usd: 0.075],
      margin_funding_fee: [btc_usd: 0.01, eth_usd: 0.01]
  end


  describe "__using__/1" do
    test "(arity 0 functions): default values work" do
      assert DefaultExchange.supported_assets() == MapSet.new([])
      assert DefaultExchange.supported_sides() == MapSet.new([])
    end

    test "(arity 1 functions): default values work" do
      assert DefaultExchange.transaction_fee(:eth_usd) == 0.0
      assert DefaultExchange.withdrawal_fee(:eth_usd) == 0.0
      assert DefaultExchange.margin_funding_fee(:eth_usd) == 0.0
    end

    test "(arity 0 functions): defaults can be overridden" do
      assert ConfiguredExchange.supported_assets() == MapSet.new([:btc, :eth, :usd])
      assert ConfiguredExchange.supported_sides() == MapSet.new([:buy])
    end

    test "(arity 1 functions): defaults can be overridden" do
      assert ConfiguredExchange.transaction_fee(:btc_usd) == 0.025
      assert ConfiguredExchange.transaction_fee(:eth_usd) == 0.05

      assert ConfiguredExchange.withdrawal_fee(:btc_usd) == 0.075
      assert ConfiguredExchange.withdrawal_fee(:eth_usd) == 0.075

      assert ConfiguredExchange.margin_funding_fee(:btc_usd) == 0.01
      assert ConfiguredExchange.margin_funding_fee(:eth_usd) == 0.01
    end
  end
end
