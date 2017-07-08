defmodule Crypto.Core.Order do
  @moduledoc """
  Module defining the structured `Order.t` for this application.

  """



  ################################################################################
  # Types
  ################################################################################

  @type side :: :buy | :sell

  @type t :: %__MODULE__{
    side: side,
    price: float,
    volume: float,
    exchange: module,
  }


  defstruct [
    side: nil,
    price: nil,
    volume: nil,
    exchange: nil
  ]
end
