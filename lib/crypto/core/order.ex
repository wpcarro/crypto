defmodule Crypto.Core.Order do
  @moduledoc """
  Module defining the structured `Order.t` for this application.

  """

  alias Crypto.Exchange



  ################################################################################
  # Types
  ################################################################################

  @type side :: :buy | :sell

  @type t :: %__MODULE__{
    side: side,
    price: float,
    volume: float,
    exchange: module,
    asset: Exchange.asset,
  }


  defstruct [
    side: nil,
    price: nil,
    volume: nil,
    exchange: nil,
    asset: nil
  ]
end
