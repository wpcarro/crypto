defmodule Cryptocurrency.Core.Storage do
  @moduledoc """
  Module for Interacting with the Rock DB instance.

  """

  import ShorterMaps
  use GenServer



  ################################################################################
  # Constants
  ################################################################################

  @default_path "/tmp/cryptocurrency/store.rocksdb"
  @path Application.get_env(:red_pill, :storage_path, @default_path)



  ################################################################################
  # Type Definitions
  ################################################################################

  @type state :: %{
    db: Rox.DB.t
  }



  ################################################################################
  # Public API
  ################################################################################

  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end


  @doc """
  Retrieves the value stored at `key` from the database.

  """
  @spec get(key :: binary) :: {:ok, value :: any} | :not_found | {:error, reason :: any}
  def get(key) do
    GenServer.call(__MODULE__, {:get, key})
  end


  @doc """
  Saves `value` in the database at `key`.

  """
  @spec put(key :: binary, value :: any) :: :ok | {:error, reason :: any}
  def put(key, value) do
    GenServer.call(__MODULE__, {:put, key, value})
  end


  @doc """
  Deletes the key-value entry stored in the database at `key`.

  """
  @spec delete(key :: binary) :: :ok | {:error, reason :: any}
  def delete(key) do
    GenServer.call(__MODULE__, {:delete, key})
  end



  ################################################################################
  # GenServer Callbacks
  ################################################################################

  def init(:ok) do
    {:ok, db} =
      Rox.open(@path, create_if_missing: true)

    state =
      %{db: db}

    {:ok, state}
  end


  def handle_call({:get, key}, _from, ~M{db} = state) do
    reply =
      Rox.get(db, key)

    {:reply, reply, state}
  end

  def handle_call({:put, key, value}, _from, ~M{db} = state) do
    reply =
      Rox.put(db, key, value)

    {:reply, reply, state}
  end

  def handle_call({:delete, key}, _from, ~M{db} = state) do
    reply =
      Rox.delete(db, key)

    {:reply, reply, state}
  end

end
