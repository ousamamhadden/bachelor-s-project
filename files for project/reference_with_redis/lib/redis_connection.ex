defmodule MiniGroupCall.Redix do
  @pool_size 1000

  def child_spec(_args) do
    # Specs for the Redix connections.

    ## wait for redis to come up
    # for index <- 0..(@pool_size - 1) do
    children = [
      Supervisor.child_spec(
        {Redix, name: :redix_one, host: "refredis", password: "mypassword"},
        id: {Redix, 1}
      )
    ]

    # end

    # Spec for the supervisor that will supervise the Redix connections.
    %{
      id: RedixSupervisor,
      type: :supervisor,
      start: {Supervisor, :start_link, [children, [strategy: :one_for_one]]}
    }
  end

  def command(command) do
    Redix.command!(:redix_one, command)
  end

  defp random_index() do
    Enum.random(0..(@pool_size - 1))
  end
end
