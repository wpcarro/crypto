defmodule Cryptocurrency.Core.OrderBook.Entry do
  @moduledoc """
  Module defining a genericized `OrderBook` entry.

  """


  defstruct [
    price: nil,
    volume: nil,
    extra: %{},
  ]



  ################################################################################
  # Types
  ################################################################################

  @type t :: %__MODULE__{
    price: float,
    volume: float,
    extra: map
  }

end
