defmodule Cryptocurrency.Core.Order do
  @moduledoc """
  Module defining the structured `Order.t` for this application.

  """

  alias Cryptocurrency.Exchange



  ################################################################################
  # Types
  ################################################################################

  @type side :: :buy | :sell

  @type t :: %__MODULE__{
    side: side,
    price: float,
    volume: float,
    exchange: module,
    asset_pair: Exchange.asset_pair,
  }


  defstruct [
    side: nil,
    price: nil,
    volume: nil,
    exchange: nil,
    asset_pair: nil
  ]
end
