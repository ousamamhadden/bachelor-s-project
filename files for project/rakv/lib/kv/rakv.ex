defmodule RAKV do
  @moduledoc """
  Documentation for `RAKV`.
  """

  @ra_cluster_name :coffeemachines
  @raft_starter :"rakv@rakv-0.rakv-cluster.ngcp-dev.svc.cluster.local"

  def open_bakery(_nodes) do
    # cluster starter needs to wait a bit for all node to start ra
    IO.puts("I got here 111")

    if File.exists?('rakvdata/' ++ Atom.to_charlist(Node.self())) do
      :ra.start(data_dir: '/app/rakvdata', wal_data_dir: '/app')

      :ra.restart_server({@ra_cluster_name, Node.self()})
      IO.puts("Volume is persistant!!!")
    else
      :ra.start(data_dir: '/app/rakvdata', wal_data_dir: '/app')

      if Node.self() == @raft_starter do
        start_cluster()
        IO.puts("I got here 222")
      else
        {:ok, _, _} =
          :ra.add_member(
            {@ra_cluster_name, @raft_starter},
            {@ra_cluster_name, Node.self()}
          )

        :ok = start_server()
      end
    end
  end

  @behaviour :ra_machine

  def hello do
    :world
  end

  @impl true
  def init(_config) do
    %{}
  end

  @impl true
  @spec apply(
          any,
          {:buy, any}
          | {:start, any}
          | {:take, any}
          | {:turn_off, any}
          | {:insert_money, any, any},
          map
        ) :: {map, any}
  def apply(_metadata, {:start, id}, state) do
    {reply, new_state} = CoffeeMachines.start(state, id)

    {new_state, reply}
  end

  @impl true

  def apply(_metadata, {:insert_money, id, amount}, state) do
    {reply, new_state} = CoffeeMachines.insert_money(state, id, amount)
    {new_state, reply}
  end

  @impl true

  def apply(_metadata, {:buy, id}, state) do
    {reply, new_state} = CoffeeMachines.buy(state, id)
    {new_state, reply}
  end

  @impl true

  def apply(_metadata, {:take, id}, state) do
    {reply, new_state} = CoffeeMachines.take(state, id)
    {new_state, reply}
  end

  @impl true

  def apply(_metadata, {:turn_off, id}, state) do
    {reply, new_state} = CoffeeMachines.turn_off(state, id)
    {new_state, reply}
  end

  ## Client API
  def start(serverId, id) do
    :ra.process_command(serverId, {:start, id})
  end

  @spec insert_money(atom | pid | {atom, any} | {:via, atom, any}, any, any) :: any
  def insert_money(serverId, id, amount) do
    :ra.process_command(serverId, {:insert_money, id, amount})
  end

  def buy(serverId, id) do
    :ra.process_command(serverId, {:buy, id})
  end

  def take(serverId, id) do
    :ra.process_command(serverId, {:take, id})
  end

  def turn_off(serverId, id) do
    :ra.process_command(serverId, {:turn_off, id})
  end

  @spec start_cluster() ::
          {:error, :cluster_not_formed} | {:ok, [{atom, atom}, ...], keyword(atom)}
  def start_cluster() do
    serverIds = [{@ra_cluster_name, Node.self()}]
    machineConf = {:module, __MODULE__, %{}}
    :ra.start_cluster(:default, @ra_cluster_name, machineConf, serverIds)
  end

  @spec start_server :: :ok | {:error, any}
  def start_server() do
    my_id = {@ra_cluster_name, Node.self()}
    machineConf = {:module, __MODULE__, %{}}

    :ra.start_server(
      :default,
      @ra_cluster_name,
      my_id,
      machineConf,
      [{@ra_cluster_name, @raft_starter}]
    )
  end
end
