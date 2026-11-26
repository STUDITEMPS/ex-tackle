defmodule Tackle.MultipleServicesTest do
  use ExUnit.Case

  require Support

  alias Support.MessageTrace

  defmodule ServiceA do
    require Logger

    @rabbitmq_url Application.compile_env(:tackle, :rabbitmq_url)

    use Tackle.Consumer,
      rabbitmq_url: @rabbitmq_url,
      remote_exchange: "ex-tackle.test-exchange",
      routing_key: "a",
      service: "ex-tackle.serviceA",
      retry_delay: 1,
      retry_limit: 3

    def handle_message(message) do
      Logger.info("ServiceA: received '#{message}'")

      message |> MessageTrace.save("serviceA")
    end
  end

  # broken service
  defmodule ServiceB do
    require Logger

    @rabbitmq_url Application.compile_env(:tackle, :rabbitmq_url)

    use Tackle.Consumer,
      rabbitmq_url: @rabbitmq_url,
      remote_exchange: "ex-tackle.test-exchange",
      routing_key: "a",
      service: "ex-tackle.serviceB",
      retry_delay: 1,
      retry_limit: 3

    def handle_message(message) do
      Logger.info("ServiceB: received '#{message}'")

      message |> MessageTrace.save("serviceB")

      raise "broken"
    end
  end

  @publish_options %{
    rabbitmq_url: Application.compile_env(:tackle, :rabbitmq_url),
    exchange: "ex-tackle.test-exchange",
    routing_key: "a"
  }

  setup do
    Support.cleanup!(ServiceA)
    Support.cleanup!(ServiceB)

    on_exit(fn ->
      Support.cleanup!(ServiceA)
      Support.cleanup!(ServiceB)
    end)

    MessageTrace.clear("serviceA")
    MessageTrace.clear("serviceB")

    {:ok, service_a} = ServiceA.start_link()
    {:ok, service_b} = ServiceB.start_link()

    # publish only after both queues are bound to the exchange, otherwise the
    # message is dropped
    Support.wait_consumer_ready(service_a)
    Support.wait_consumer_ready(service_b)

    :ok
  end

  describe "multiple services listening on the same exchange with the same routing_key" do
    test "sends message to both services" do
      Tackle.publish("Hi!", @publish_options)

      :timer.sleep(5000)

      assert MessageTrace.content("serviceA") |> String.contains?("Hi!")
      assert MessageTrace.content("serviceB") |> String.contains?("Hi!")
    end

    test "sends the message only once to the healthy service" do
      Tackle.publish("Hi!", @publish_options)

      :timer.sleep(5000)

      assert MessageTrace.content("serviceA") == "Hi!"
    end

    test "sends the message multiple times to the broken service" do
      Tackle.publish("Hi!", @publish_options)

      :timer.sleep(5000)

      assert MessageTrace.content("serviceB") == "Hi!Hi!Hi!Hi!"
    end
  end
end
