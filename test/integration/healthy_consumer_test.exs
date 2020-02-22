defmodule Tackle.HealthyConsumerTest do
  use ExSpec

  alias Support.MessageTrace

  defmodule TestConsumer do
    use Tackle.Consumer,
      rabbitmq_url: "amqp://localhost",
      remote_exchange: "ex-tackle.test-exchange",
      routing_key: "health",
      service: "ex-tackle.healthy-service"

    def handle_message(message) do
      message |> MessageTrace.save("healthy-service")
    end
  end

  @publish_options %{
    rabbitmq_url: "amqp://localhost",
    exchange: "ex-tackle.test-exchange",
    routing_key: "health"
  }

  setup do
    Support.cleanup!(TestConsumer)

    on_exit(fn ->
      Support.cleanup!(TestConsumer)
    end)

    MessageTrace.clear("healthy-service")

    {:ok, _} = TestConsumer.start_link()

    :timer.sleep(1000)
  end

  describe "healthy consumer" do
    it "knows the routing key" do
      assert TestConsumer.routing_key() == "health"
    end

    it "receives a published message on the exchange" do
      Tackle.publish("Hi!", @publish_options)

      :timer.sleep(1000)

      assert MessageTrace.content("healthy-service") == "Hi!"
    end
  end
end
