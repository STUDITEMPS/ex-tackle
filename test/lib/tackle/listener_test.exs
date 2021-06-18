defmodule Tackle.ListenerTest do
  use ExSpec

  defmodule TestConsumer do
    require Logger

    use Tackle.Consumer,
      rabbitmq_url: "amqp://localhost",
      remote_exchange: "ex-tackle.test-exchange",
      routing_key: "test-messages",
      service: "ex-tackle.test-service"

    def handle_message(_message) do
      Logger.debug("here")
    end
  end

  setup do
    Support.cleanup!(TestConsumer)

    on_exit(fn ->
      Support.cleanup!(TestConsumer)
    end)
  end

  describe "consumer creation" do
    it "connects to amqp server without errors" do
      {response, _consumer} = TestConsumer.start_link()

      assert response == :ok
    end

    it "creates a queue on the amqp server" do
      {_response, _consumer} = TestConsumer.start_link()

      :timer.sleep(1000)

      queues = Support.rabbitmq_list_queues

      assert Enum.member?(queues, "ex-tackle.test-service.test-messages")
      assert Enum.member?(queues, "ex-tackle.test-service.test-messages.delay.10")
      assert Enum.member?(queues, "ex-tackle.test-service.test-messages.dead")
    end

    it "creates an exchange on the amqp server" do
      {_response, _consumer} = TestConsumer.start_link()

      :timer.sleep(1000)

      exchanges = Support.rabbitmq_list_exchanges

      assert Enum.member?(exchanges, "ex-tackle.test-service.test-messages")
    end
  end
end
