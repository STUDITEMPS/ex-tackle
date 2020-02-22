defmodule Tackle.DeadQueueTest do
  use ExSpec

  defmodule DeadConsumer do
    use Tackle.Consumer,
      rabbitmq_url: "amqp://localhost",
      remote_exchange: "ex-tackle.test-exchange",
      routing_key: "test-messages",
      service: "ex-tackle.dead-service",
      retry_delay: 1,
      retry_limit: 3

    def handle_message(_message) do
      # exception without warning
      Code.eval_quoted(quote do: :a + 1)
    end
  end

  @publish_options %{
    rabbitmq_url: "amqp://localhost",
    exchange: "ex-tackle.test-exchange",
    routing_key: "test-messages"
  }

  @dead_queue "ex-tackle.dead-service.test-messages.dead"

  setup do
    Support.cleanup!(DeadConsumer)

    on_exit(fn ->
      Support.cleanup!(DeadConsumer)
    end)

    {:ok, _} = DeadConsumer.start_link()

    :timer.sleep(1000)

    Support.purge_queue(@dead_queue)
  end

  describe "broken consumer" do
    it "puts the messages o dead queue after failures" do
      assert Support.queue_status(@dead_queue).message_count == 0

      Tackle.publish("Hi!", @publish_options)
      :timer.sleep(5000)

      assert Support.queue_status(@dead_queue).message_count == 1
    end
  end
end
