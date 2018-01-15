defmodule Cryptocurrency.Forex do
  use GenServer
  
  
  
  ################################################################################ 
  # Constants
  ################################################################################ 
  
  @cache_ttl 1000 * 60 * 60
  @api_url "http://apilayer.net/api/live"
  @access_key Application.get_env(:cryptocurrency, :currency_layer_access_key)

  

  ################################################################################ 
  # Typespecs
  ################################################################################ 
  
  @type currency :: :usd | :krw

  @typedoc """
  Exchange rate in 1/1000ths of cents

  """
  @type exchange_rate :: integer
  
  
  @typep state :: %{
    rates:        %{optional({currency, currency}) => exchange_rate},
    cache_timers: %{optional({currency, currency}) => exchange_rate}
   }


  
  ################################################################################ 
  # Public API
  ################################################################################ 
  
  @spec start_link(:ok) :: GenServer.on_start
  def start_link(:ok),
    do: GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  

  @doc """
  Returns the exchange rate between two currency symbols, represented as
  thousandths of a cent.

  Will fetch the exchange rate if it is not previously cached, and thereafter
  cache the response for 1 hour

  ## Options

    * `:to` - `currency` to which we will be converting.
    * `:from` - `currency` from which we will be converting.

  """
  @spec rate(opts) :: exchange_rate
    when opts: [{:to, currency} | {:from, currency} | {:force, boolean}]
  def rate(opts) do
    sell_currency =
      Keyword.fetch!(opts, :from)

    buy_currency =
      Keyword.fetch!(opts, :to)

    GenServer.call(__MODULE__, {:rate, sell_currency, buy_currency, opts})
  end


  
  ################################################################################ 
  # GenServer callbacks
  ################################################################################ 
  
  @impl GenServer
  def init(:ok) do
    {:ok, %{rates: %{}, cache_timers: %{}}}
  end
  
  
  @impl GenServer
  def handle_call({:rate, sell_currency, buy_currency, opts}, _from, state) do
    case {fetch_cached_rate(state, sell_currency, buy_currency),
          Keyword.get(opts, :force, false)} do
      {{:ok, rate}, false} ->
        {:reply, rate, state}
        
      {cached, force} when cached == :error or force == true ->
        state = 
          cancel_timer(state, sell_currency, buy_currency)
        
        rate =
          load_rate(sell_currency, buy_currency)
        
        timer =
          Process.send_after(
            self(),
            {:clear_cache, sell_currency, buy_currency},
            @cache_ttl
          )
        
        state = state
          |> put_in([:rates, {sell_currency, buy_currency}], rate)
          |> put_in([:cache_timers, {sell_currency, buy_currency}], timer)
        
        {:reply, rate, state}
    end
  end
  
  
  
  ################################################################################ 
  # Private Helpers
  ################################################################################ 
  
  @spec fetch_cached_rate(state, currency, currency) :: {:ok, exchange_rate} | :error
  defp fetch_cached_rate(%{rates: rates}, sell, buy) do
    Map.fetch(rates, {sell, buy})
  end
  
  
  @spec load_rate(currency, currency) :: exchange_rate | no_return
  defp load_rate(sell, buy) do
    %HTTPoison.Response{status_code: 200, body: response_body} =
      HTTPoison.get!(@api_url, [], params: %{
        format: "1",
        source: format_currency(sell),
        currencies: format_currency(buy),
        access_key: @access_key
      })
    
    quote_symbol = # ie USDKRW
      format_currency(sell) <> format_currency(buy)
    
    body_json =
      Poison.decode!(response_body)

    body_json |> Map.fetch!("quotes") |> Map.fetch!(quote_symbol)
  end
  

  @spec cancel_timer(state, currency, currency) :: state
  defp cancel_timer(%{cache_timers: timers} = state, sell_currency, buy_currency) do
    {timer, timers} =
      Map.pop(timers, {sell_currency, buy_currency})
    
    if not is_nil(timer), do: Process.cancel_timer(timer)
    
    %{state | cache_timers: timers}
  end
  
  
  @spec format_currency(currency) :: binary
  defp format_currency(currency) do
    currency
    |> Atom.to_string()
    |> String.upcase()
  end

end
