defmodule MockExchange do
  @moduledoc """
  Exchange module useful for testing.

  """
  defmacro __using__(opts \\ []) do
    quote do
      use Cryptocurrency.Exchange, unquote(opts)
    end
  end
end

ExUnit.start()
