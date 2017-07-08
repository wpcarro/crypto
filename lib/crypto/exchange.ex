defmodule Crypto.Exchange do
  @moduledoc """
  Module defining the Exchange `behaviour` callbacks for children modules.

  """

  alias Crypto.Core.{Order, OrderBook}



  ################################################################################
  # Types
  ################################################################################

  @type asset_pair :: :eth_usd | :eth_btc | :btc_usd | :ltc_usd


  ################################################################################
  # Callbacks
  ################################################################################

  @callback fetch_order_book(asset_pair) :: OrderBook.t

  @callback transaction_fee(Order.t) :: float

  @callback execute_orders([Order.t]) :: :ok | {:error, reason :: any}
end
