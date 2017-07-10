defmodule Crypto.Exchange do
  @moduledoc """
  Module defining the Exchange `behaviour` callbacks for children modules.

  """

  alias Crypto.Core.{Order, OrderBook}



  ################################################################################
  # Types
  ################################################################################

  @type t :: module
  @type asset :: :eth | :btc | :ltc | :usd | :eur | :gbp
  @type asset_pair :: :eth_usd | :eth_btc | :btc_usd | :ltc_usd


  ################################################################################
  # Callbacks
  ################################################################################

  @callback fetch_order_book(asset_pair) :: OrderBook.t

  @callback transaction_fee(asset_pair) :: float

  @callback withdrawal_fee(asset_pair) :: float

  @callback execute_orders([Order.t]) :: :ok | {:error, reason :: any}

  @callback supported_assets :: MapSet.t(asset)

  @callback supported_sides :: MapSet.t(Order.side)

  @callback send_to_exchange(keyword) :: :ok | {:error, reason :: any}

  @callback wallet_address(asset) :: binary

end
