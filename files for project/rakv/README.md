

*How to use currently

Start multiple nodes in this project with: `iex --sname {name} -S mix` for each node

start ra: `:ra.start()` on each raft node


connect all the nodes: `Node.connect({nodename})`

start the cluster in one of the ra nodes: `RAKV.start({atom_cluster_name},Node.list())`


clients can be on the same nodes as the ra node or they can be on a seperate node that needs to connect to the cluster

For a client in a ra node:
RAKV.{command}([{atom_cluster_name},{a node name}], arg1, arg2... )

For a client outside the ra node we can use :rpc module:
Node.connect(:rakv@host1)
:rpc.call(:rakv@host3,RAKV,:put,[{:test1234,:rakv@host2},:c,225])
:rpc.call(:rakv@host3,RAKV,:get,[{:test1234,:rakv@host1},:b])


normal kv 
:rpc.call(:rakv@host4,Normalkv,:put,[Normalkv,:c,225])
:rpc.call(:rakv@host4,Normalkv,:get,[Normalkv,:c])
*With docker

`make build-dev-docker` and `test-local-env-restart` would build and start the docker containers
rakv_1, rakv_2 and rakv_3 are nodes that use ra.
rakv_4 is just a genserver not using ra
finally we start a container in interactive mode that can interact with either the genserver from rakv_4 or the ra cluster from its nodes.
Examples for interacting with the cluster:
Node.connect(:rakv@host1)
:rpc.call(:rakv@host3,RAKV,:put,[{:test123,:rakv@host2},:c,225])
:rpc.call(:rakv@host3,RAKV,:get,[{:test123,:rakv@host1},:c])


TODO:
-create timer in the client and a sernario for test
-see performance when the memory is used instead of disk
