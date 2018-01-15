defmodule Cryptocurrency.Application do
  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  alias Cryptocurrency.Pipeline.Maestro
  alias Cryptocurrency.Core.Storage

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    :ok = Cryptocurrency.Statsd.connect()

    # Define workers and child supervisors to be supervised
    children = [
      # Starts a worker by calling: Cryptocurrency.Worker.start_link(arg1, arg2, arg3)
      # worker(Cryptocurrency.Worker, [arg1, arg2, arg3]),
      worker(Maestro, []),
      worker(Storage, []),
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Cryptocurrency.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
