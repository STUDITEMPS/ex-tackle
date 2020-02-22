defmodule Tackle.BrokenConsumerTest do
  use ExSpec

  alias Support.MessageTrace

  defmodule BrokenConsumer do
    use Tackle.Consumer,
      rabbitmq_url: "amqp://localhost",
      remote_exchange: "ex-tackle.test-exchange",
      routing_key: "test-messages",
      service: "ex-tackle.broken-service",
      retry_delay: 1,
      retry_limit: 3

    def handle_message(message) do
      message |> MessageTrace.save("broken-service")

      # exception without warning
      Code.eval_quoted(quote do: :a + 1)
    end
  end

  @publish_options %{
    rabbitmq_url: "amqp://localhost",
    exchange: "ex-tackle.test-exchange",
    routing_key: "test-messages"
  }

  setup do
    Support.cleanup!(BrokenConsumer)

    on_exit(fn ->
      Support.cleanup!(BrokenConsumer)
    end)

    MessageTrace.clear("broken-service")

    {:ok, _} = BrokenConsumer.start_link()

    :timer.sleep(1000)
  end

  describe "healthy consumer" do
    it "receives the message multiple times" do
      Tackle.publish("Hi!", @publish_options)

      :timer.sleep(5000)

      assert MessageTrace.content("broken-service") == "Hi!Hi!Hi!Hi!"
    end
  end
end
