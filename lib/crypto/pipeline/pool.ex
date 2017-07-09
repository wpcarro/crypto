defmodule Crypto.Pipeline.Pool do
  @moduledoc """
  Module responsible for matchmaking exchanges based on the currencies they support.

  """

  alias Crypto.Exchange



  ################################################################################
  # Types
  ################################################################################

  @type t :: %__MODULE__{
    shared_assets: MapSet.t(Exchange.asset),
    exchanges: MapSet.t(Exchange.t)
  }

  defstruct [
    shared_assets: nil,
    exchanges: nil
  ]



  ################################################################################
  # Public API
  ################################################################################

  @doc """
  Combines exchanges based on the common assets between each.

  """
  @spec matchmake([Exchange.t]) :: [t]
  def matchmake(_exchanges) do
  end

end
