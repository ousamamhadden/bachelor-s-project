defmodule KVApp do
  use Application

  # defp connect_to_nodes(args) do
  #   if length(args) - 1 != length(Node.list()) do
  #     IO.puts("Trying to connect the nodes")
  #     Enum.map(Node.list(), fn node -> IO.puts(node) end)
  #     Enum.map(args, fn node -> Node.connect(node) end)
  #     connect_to_nodes(args)
  #   end
  # end

  def start(_, _args) do
    children = [
      Supervisor.child_spec(
        {Task,
         fn ->
           Balancer.start_system()
         end},
        id: :worker1
      )
    ]

    # Supervisor.start_link(children, strategy: :one_for_one)
    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
