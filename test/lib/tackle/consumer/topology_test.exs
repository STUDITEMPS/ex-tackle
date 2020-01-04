defmodule Tackle.Consumer.TopologyTest do
  use ExSpec
  alias Tackle.Consumer.Topology

  it "knows all the queue and exchange names generated" do
    assert topology =
             Topology.new(
               service: "my_service",
               remote_exchange: "remote_ex",
               routing_key: "route.me",
               retry: [delay: 2, limit: 10]
             )

    assert topology.remote_exchange == "remote_ex"
    assert topology.message_exchange == "my_service.route.me"
    assert topology.routing_key == "route.me"
    assert topology.consume_queue == "my_service.route.me"
    assert topology.delay_queue == "my_service.route.me.delay.2"
    assert topology.dead_queue == "my_service.route.me.dead"
    assert topology.retry_delay == 2
    assert topology.retry_limit == 10
  end

  it "sets default retry options" do
    assert topology =
             Topology.new(
               service: "my_service",
               remote_exchange: "remote_ex",
               routing_key: "route.me",
               retry: true
             )

    assert topology.retry_delay == 10
    assert topology.retry_limit == 10
  end

  it "can disable retries" do
    assert topology =
             Topology.new(
               service: "my_service",
               remote_exchange: "remote_ex",
               routing_key: "route.me",
               retry: false
             )

    assert topology.retry_delay == 0
    assert topology.retry_limit == 0
  end
end
