defmodule Balancer do
  @moduledoc """
  Documentation for `RAKV`.
  """

  @time_window_for_clients 1000

  @ra_cluster_name :mini_group_call
  @raft_starter :"rakv@rakv-0.rakv-cluster.ngcp-dev.svc.cluster.local"

  def start_system() do
    # cluster starter needs to wait a bit for all node to start ra
    :ra.start()
  end

  @behaviour :ra_machine

  @impl true
  def init(_config) do
    %{
      systems: [],
      nodes: [:a@PDWF36, :b@PDWF36, :c@PDWF36],
      balancing: false,
      a@PDWF36: [],
      b@PDWF36: [],
      c@PDWF36: []
    }
  end

  @impl true
  def state_enter(:leader, state) do
    if state.balancing do
      [
        {:timer, :balancing, @time_window_for_clients}
      ]
    else
      []
    end
  end

  def state_enter(_, _) do
    []
  end

  @impl true
  def apply(_metadata, {:balance, new_node}, state) do
    # problimatic
    if state.balancing do
      {state, :currently_balancing}
    else
      systems_allowed_to_move = state.systems
      nodes = state.nodes
      number_of_systems = length(state.systems)
      number_of_old_nodes = length(nodes)
      number_of_nodes = length(nodes) + 1

      number_of_systems_to_move_per_node =
        float_to_int(Float.floor(number_of_systems - number_of_systems * 3 / number_of_nodes))

      number_of_target_systems_in_new_node =
        number_of_systems_to_move_per_node * number_of_old_nodes

      nodes_credit =
        for i <- nodes do
          for _j <- 1..number_of_systems_to_move_per_node do
            i
          end
        end
        |> Enum.reduce([], &(&2 ++ &1))

      new_state =
        state
        |> Map.put(:nodes, nodes ++ [new_node])
        |> Map.put(:new_node, new_node)
        |> Map.put(:balancing, true)
        |> Map.put(:systems_in_new, [])
        |> Map.put(:systems_allowed_to_move, systems_allowed_to_move)
        |> Map.put(:nodes_credit, nodes_credit)
        |> Map.put(new_node, [])
        |> Map.put(:number_of_target_systems_in_new_node, number_of_target_systems_in_new_node)

      {new_state, :starting_balancing, [{:timer, :balancing, @time_window_for_clients}]}
    end
  end

  def apply(_metadata, {:timeout, :balancing}, state) do
    number_of_target_systems_in_new_node = state.number_of_target_systems_in_new_node
    new_node = state.new_node
    systems_in_new = Map.get(state, new_node)

    if length(systems_in_new) >= number_of_target_systems_in_new_node do
      new_state =
        state
        |> Map.put(:balancing, false)
        |> Map.delete(:new_node)
        |> Map.delete(:systems_in_new)
        |> Map.delete(:systems_allowed_to_move)
        |> Map.delete(:nodes_credit)
        |> Map.delete(:number_of_target_systems_in_new_node)

      {new_state, :balancing_finished}
    else
      IO.puts("GOT HERE 0")

      {state, :starting_balancing,
       [
         {:timer, :balancing, @time_window_for_clients},
         {:mod_call, BalancerHelper, :test, [state]}
       ]}
    end
  end

  def apply(_metadata, {:balancing_update, new_state}, state) do
    if state.balancing do
      {new_state, :state_updated,
       [
         {:timer, :balancing, @time_window_for_clients}
       ]}
    else
      {state, :cannot_update}
    end
  end

  def apply(_metadata, {:add_system, cluster_name, nodes}, state) do
    new_state = state |> Map.update!(:systems, fn systems -> systems ++ [cluster_name] end)

    new_state =
      Enum.reduce(nodes, new_state, fn node, current_state ->
        Map.update!(current_state, node, fn systems -> systems ++ [cluster_name] end)
      end)

    {new_state, :system_added, [{:timer, :balancing, @time_window_for_clients}]}
  end

  def balancing_update(new_state) do
    :ra.process_command({:main, Node.self()}, {:balancing_update, new_state})
  end

  def balance(serverId, new_node) do
    :ra.process_command(serverId, {:balance, new_node})
  end

  def start_cluster(cluster_name, members) do
    serverIds = Enum.map(members, fn a -> {cluster_name, a} end)
    machineConf = {:module, __MODULE__, %{}}
    :ra.start_cluster(:default, cluster_name, machineConf, serverIds)
  end

  @spec start_server(atom, atom, any) :: :ok | {:error, any}
  def start_server(cluster_name, node_name, cluster_members) do
    my_id = {cluster_name, node_name}
    machineConf = {:module, __MODULE__, %{}}
    member_ids = Enum.map(cluster_members, fn a -> {cluster_name, a} end)

    :ra.start_server(
      :default,
      cluster_name,
      my_id,
      machineConf,
      member_ids
    )
  end

  def float_to_int(float) do
    {int, _} = Integer.parse(Float.to_string(float))
    int
  end
end
