defmodule Cryptocurrency.Core.Scheduler do
  @moduledoc """
  Module responsible for scheduling a function to run every N seconds.

  This is analogous to JavaScript's setInterval function but with higher fidelity.

  """


  @doc """
  Runs `callback` at an interval specified by `opts`.

  ## Options

    * `{:hours, non_neg_integer}`
    * `{:minutes, non_neg_integer}`
    * `{:seconds, non_neg_integer}`

  """
  @spec every((any -> any), keyword) :: :ok | no_return
  def every(callback, opts) do
    Keyword.Extra.assert_any!([:hours, :minutes, :seconds])

    # Stream.iterate(Timex.now(), &Timex.shift(&1, offset))
  end
end
