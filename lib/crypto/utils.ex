defmodule Crypto.Utils do
  @moduledoc """
  Module hosting utility functions for common decoding tasks.

  """


  @doc """
  Forcefully parses a float.

  """
  @spec parse_float(binary) :: float
  def parse_float(input) do
    {result, ""} =
      Float.parse(input)

    result
  end


  @doc """
  Forcefully parses an integer.

  """
  @spec parse_int(binary) :: integer
  def parse_int(input) do
    {result, ""} =
      Integer.parse(input)

    result
  end

end
