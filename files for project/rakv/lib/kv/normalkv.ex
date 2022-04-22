defmodule Normalkv do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  ## Client API
  def start(server, id) do
    GenServer.call(server, {:start, id})
  end

  @spec insert_money(atom | pid | {atom, any} | {:via, atom, any}, any, any) :: any
  def insert_money(server, id, amount) do
    GenServer.call(server, {:insert_money, id, amount})
  end

  def buy(server, id) do
    GenServer.call(server, {:buy, id})
  end

  def take(server, id) do
    GenServer.call(server, {:take, id})
  end

  def turn_off(server, id) do
    GenServer.call(server, {:turn_off, id})
  end

  ## Defining GenServer Callbacks

  @impl true
  def init(:ok) do
    IO.puts("initiated")
    {:ok, %{}}
  end

  @impl true
  def handle_call({:start, id}, _from, state) do
    {reply, new_state} = CoffeeMachines.start(state, id)
    {:reply, reply, new_state}
  end

  @impl true
  def handle_call({:insert_money, id, amount}, _from, state) do
    {reply, new_state} = CoffeeMachines.insert_money(state, id, amount)
    {:reply, reply, new_state}
  end

  @impl true
  def handle_call({:buy, id}, _from, state) do
    {reply, new_state} = CoffeeMachines.buy(state, id)
    {:reply, reply, new_state}
  end

  @impl true
  def handle_call({:take, id}, _from, state) do
    {reply, new_state} = CoffeeMachines.take(state, id)
    {:reply, reply, new_state}
  end

  @impl true
  def handle_call({:turn_off, id}, _from, state) do
    {reply, new_state} = CoffeeMachines.turn_off(state, id)
    {:reply, reply, new_state}
  end
end
