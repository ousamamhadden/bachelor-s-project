defmodule BalancerHelper do
  def test(state) do
    Task.async(fn ->
      transfer_raft_node(state)
    end)

    IO.puts("GOT HERE 2")
  end

  def create_cluster(cluster_name) do
    nodes = [:a@PDWF36, :b@PDWF36, :c@PDWF36]
    {:ok, _, _} = RAKV.start_cluster(cluster_name, nodes)

    {:ok, _, _} =
      :ra.process_command(
        [{:main, :a@PDWF36}, {:main, :b@PDWF36}, {:main, :c@PDWF36}],
        {:add_system, cluster_name, nodes}
      )

    {:system_created, nodes}
  end

  def transfer_raft_node(state) do
    if state.balancing == false do
      {:error, "cannot transfer nodes when not balancing"}
    else
      new_node = state.new_node
      # systems_in_new = state.systems_in_new
      systems_allowed_to_move = state.systems_allowed_to_move
      nodes_credit = state.nodes_credit
      system_to_move = systems_allowed_to_move |> List.first()

      node_to_move_it_from =
        Enum.filter(state.nodes, fn node ->
          node in nodes_credit and system_to_move in Map.get(state, node)
        end)
        |> List.first()

      :ra.add_member({system_to_move, node_to_move_it_from}, {system_to_move, new_node})

      case RAKV.start_server(system_to_move, new_node, [:a@PDWF36, :b@PDWF36, :c@PDWF36]) do
        :ok ->
          :ra.leave_and_delete_server(
            system_to_move,
            {system_to_move, new_node},
            {system_to_move, node_to_move_it_from}
          )

        {:error, {:shutdown, {:failed_to_start_child, :main, {:already_started, _}}}} ->
          :ra.leave_and_delete_server(
            system_to_move,
            {system_to_move, new_node},
            {system_to_move, node_to_move_it_from}
          )

        _ ->
          IO.puts("ERROR!!")
      end

      new_state =
        state
        |> Map.update!(:systems_allowed_to_move, fn list -> list -- [system_to_move] end)
        |> Map.update!(new_node, fn list -> list ++ [system_to_move] end)
        |> Map.update!(node_to_move_it_from, fn list -> list -- [system_to_move] end)
        |> Map.update!(:nodes_credit, fn list -> list -- [node_to_move_it_from] end)

      IO.puts("#{inspect(new_state)}")
      Balancer.balancing_update(new_state)
    end
  end

  # :rpc(start_server) (:ra.add_member + :ra.start_server (:ra.leave_and_delete_server))
  # :rpc(kill_server) (:ra.leave_and_delete_server)
  # update_state

  #   get_all_systems |> available_systems_to_move
  #   get_number_of_nodes |> value
  #   system_in_new = []
  #   credits = [value * node1, value * node2(...)]
  #   while(Enum.length(system_in_new) < value)

  #   get_one_system_from_available
  #   |> get_a_node
  #   |> check_if_there_is_credit_for_it
  #   |> add_new_node_to_sys
  #   |> remove_sys_from_available_systems_to_move
  #   |> add_sys_to_new
  #   |> remove_old_node_from_sys
  #   |> remove_credit
end
