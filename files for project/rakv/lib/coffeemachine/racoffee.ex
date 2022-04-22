defmodule RACoffee do
  @moduledoc """
  Documentation for `RAKV`.
  """

  def coffee(_nodes) do
    # cluster starter needs to wait a bit for all node to start ra
    IO.puts("I got here 111")

    # :ra.start(data_dir: '/app/rakvdata')
    :ra.start()
  end

  @behaviour :ra_machine

  @impl true
  def init(_config) do
    [state: :idle, money: 0, coffee: 0]
  end

  @impl true

  @spec apply(
          any,
          {:buy} | {:take} | {:turn_off} | {:insert_money, any},
          nil | maybe_improper_list | map
        ) ::
          {nil | maybe_improper_list | map,
           :a_delicious_cup_of_coffee
           | :cannot_insert_money_now
           | :cannot_take_coffe_now
           | :cannot_turn_off_now
           | :coffee_bought
           | :money_inserted
           | :not_enough_money
           | :turned_off}
  def apply(_metadata, {:insert_money, amount}, state) do
    {reply, new_state} = CoffeeMachine.insert_money(state, amount)
    {new_state, reply}
  end

  @impl true

  def apply(_metadata, {:buy}, state) do
    {reply, new_state} = CoffeeMachine.buy(state)
    {new_state, reply}
  end

  @impl true

  def apply(_metadata, {:take}, state) do
    {reply, new_state} = CoffeeMachine.take(state)
    {new_state, reply}
  end

  def apply(_metadata, {:turn_off}, state) do
    {reply, new_state} = CoffeeMachine.turn_off(state)
    {new_state, reply}
  end

  ## Client API
  def start(id) do
    start_cluster(id)
  end

  def insert_money(id, amount) do
    :ra.process_command({id, Node.self()}, {:insert_money, amount})
  end

  @spec buy(atom) :: {:error, any} | {:timeout, {atom, atom}} | {:ok, any, {atom, atom}}
  def buy(id) do
    :ra.process_command({id, Node.self()}, {:buy})
  end

  def take(id) do
    :ra.process_command({id, Node.self()}, {:take})
  end

  def turn_off(id) do
    {:ok, resp, _} = :ra.process_command({id, Node.self()}, {:turn_off})
    IO.puts("#{inspect(resp)}")

    case resp do
      :turned_off ->
        :ra.delete_cluster([
          {id, :"rakv@rakv-0.rakv-cluster.ngcp-dev.svc.cluster.local"},
          {id, :"rakv@rakv-1.rakv-cluster.ngcp-dev.svc.cluster.local"},
          {id, :"rakv@rakv-2.rakv-cluster.ngcp-dev.svc.cluster.local"}
        ])

        :success

      _ ->
        :failure
    end
  end

  @spec start_cluster(atom) ::
          {:error, :cluster_not_formed} | {:ok, [{atom, atom}, ...], keyword(atom)}
  def start_cluster(cluster_name) when is_atom(cluster_name) do
    serverIds = [
      {cluster_name, :"rakv@rakv-0.rakv-cluster.ngcp-dev.svc.cluster.local"},
      {cluster_name, :"rakv@rakv-1.rakv-cluster.ngcp-dev.svc.cluster.local"},
      {cluster_name, :"rakv@rakv-2.rakv-cluster.ngcp-dev.svc.cluster.local"}
    ]

    machineConf = {:module, __MODULE__, %{}}
    :ra.start_cluster(:default, cluster_name, machineConf, serverIds)
  end
end
