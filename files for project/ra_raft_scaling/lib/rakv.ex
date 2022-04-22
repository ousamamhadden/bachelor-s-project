defmodule RAKV do
  @moduledoc """
  Documentation for `RAKV`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> RAKV.hello()
      :world

  """

  @behaviour :ra_machine

  @impl true
  def init(_config) do
    %{}
  end

  @impl true
  def apply(_metadata, {:put, key, value}, state) do
    {Map.put(state, key, value), :inserted}
  end

  def apply(_metadata, {:get, key}, state) do
    a = Map.get(state, key, :key_not_found)
    {state, a}
  end

  # @impl true
  # @spec state_enter(any, any) :: [{:timer, :call_duration, 10000}]
  # def state_enter(:leader, %{}) do
  #   []
  # end

  # def state_enter(:leader, _state) do
  #   [{:timer, :call_duration, 10000}]
  # end

  # def state_enter(_, _state) do
  #   []
  # end

  def put(serverId, key, value) do
    :ra.process_command(serverId, {:put, key, value})
  end

  def get(serverId, key) do
    :ra.process_command(serverId, {:get, key})
  end

  def start_cluster(cluster_name, members) do
    serverIds = Enum.map(members, fn a -> {cluster_name, a} end)
    machineConf = {:module, __MODULE__, %{}}
    :ra.start_cluster(:default, cluster_name, machineConf, serverIds)
  end

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
end
