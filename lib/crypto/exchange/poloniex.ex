defmodule Crypto.Exchange.Poloniex do
  @moduledoc """
  Behaviour module implementing the `Crypto.Exchange` callbacks for Poloniex.

  """

  @behaviour Crypto.Exchange



  ################################################################################
  # Callback Definitions
  ################################################################################

  def fetch_order_book(asset_pair) do
    raise("Not implemented!")
  end


  def transaction_fee(_) do
    raise("Not implemented!")
  end


  def withdrawal_fee(_) do
    raise("Not implemented!")
  end


  def execute_orders(_orders) do
    raise("Not implemented!")
  end


  def supported_assets do
    raise("Not implemented!")
  end


  def supported_sides do
    raise("Not implemented!")
  end



  ################################################################################
  # Web-Socket Callbacks
  ################################################################################

  def start_link() do
    :websocket_client.start_link("wss://api.poloniex.com", __MODULE__, [])
  end


  def websocket_handle() do
  end


  def websocket_info(:start, _conn_state, state) do
  end

end
