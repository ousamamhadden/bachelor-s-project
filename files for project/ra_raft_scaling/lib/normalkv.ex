defmodule Stepup do
  use GenServer

  def start() do
    Balancer.start_cluster(:main, [:a@PDWF36, :b@PDWF36, :c@PDWF36])

    BalancerHelper.create_cluster(:one)
    BalancerHelper.create_cluster(:two)
    BalancerHelper.create_cluster(:three)
    BalancerHelper.create_cluster(:four)
    BalancerHelper.create_cluster(:five)
    BalancerHelper.create_cluster(:six)
    BalancerHelper.create_cluster(:seven)
    BalancerHelper.create_cluster(:eight)
    BalancerHelper.create_cluster(:nine)
    BalancerHelper.create_cluster(:ten)

    :ra.add_member({:main, Node.self()}, {:main, :d@PDWF36})

    Balancer.start_server(:main, :d@PDWF36, [:a@PDWF36, :b@PDWF36, :c@PDWF36])
    Balancer.balance({:main, :a@PDWF36}, :d@PDWF36)
  end
end
