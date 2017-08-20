defmodule Cryptocurrency.Exchange do
  @moduledoc """
  Module defining the Exchange `behaviour` callbacks for children modules.

  """

  alias Cryptocurrency.Core.{Order, OrderBook}



  ################################################################################
  # Types
  ################################################################################

  @type t :: module
  @type asset :: :eth | :btc | :ltc | :usd | :eur | :gbp
  @type asset_pair :: :eth_usd | :eth_btc | :btc_usd | :ltc_usd


  ################################################################################
  # Callbacks
  ################################################################################

  @doc """
  Makes an HTTP request to get the order book for a specified `asset_pair`.

  """
  @callback fetch_order_book(asset_pair) :: OrderBook.t


  @doc """
  Returns the transaction fee associated with a given `asset_pair`.

  """
  @callback transaction_fee(asset_pair) :: float


  @doc """
  Returns the withdrawal fee associated with a given `asset_pair`.

  """
  @callback withdrawal_fee(asset_pair) :: float


  @doc """
  Returns the margin funding fee associated with a given `asset` on an exchange.

  """
  @callback margin_funding_fee(asset) :: float


  @doc """
  A set of the assets an exchange supports for trading.

  """
  @callback supported_assets :: MapSet.t(asset)


  @doc """
  A set of the sides of an order an exchange supports with respect to the arbitrage strategy of
  buying (not on margin) and selling (on margin). This is usually an indicator of which exchange
  supports margin trading and future versions of this behaviour may opt for that callback instead.

  These values are used in the match-making algorithm, which pairs exchanges based on compatible
  buying and selling capabilities.

  ## Example

  If `SomeExchange.supported_sides() # => [:buy, :sell]` that indicates the `SomeExchange` permits
  buying (non-margin) and selling (margin).

  If `AnotherExchange.supported_sides() # => [:buy]` that indicates the `AnotherExchange` permits
  buying (non-margin) but does not support margin selling. Therefore `AnotherExchange` can only be
  used on the buy-side of the arbitrage strategy.

  """
  @callback supported_sides :: MapSet.t(Order.side)


  @doc """
  Buys a specified amount of an asset. This purchase is not on margin.

  """
  @callback buy(opts :: keyword) :: :ok | {:error, reason :: any}


  @doc """
  Sells a specified amount of an assert on margin.

  """
  @callback sell(opts :: keyword) :: :ok | {:error, reason :: any}


  @doc """
  Cancels an open order.

  """
  @callback cancel(opts :: keyword) :: :ok | {:error, reason :: any}


  @doc """
  Returns the outstanding, open orders -- both `:buy` and `:sell` -- for the exchange.

  Usually a coordinator, like the `Maestro`, will have a record in its state for items like this. It
  is possible (even though it ought not be) for the application's state to diverge from reality.
  This function is intended to be used to sync the application state with the exchange's state.

  """
  @callback pending_orders() :: :ok | {:error, reason :: any}


  @doc """
  Instruct the exchange to transfer coins to another exchange. The `asset` must be provided along
  with the module representing the `destination`. The destination is resolved into a wallet address
  that allows the transfer to occur.

  """
  @callback send_to_exchange(keyword) :: :ok | {:error, reason :: any}


  @doc """
  Returns the address of the digital wallet on an exchange that stores a particular asset,
  (e.g. `:etc`). This is used when resolving exchange modules into wallet addresses.

  """
  @callback wallet_address(asset) :: binary

end
