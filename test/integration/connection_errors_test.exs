defmodule Tackle.ConnectionErrorsTest do
  @moduledoc """
  Consumer should be restarted if the connection is lost.

  SLEEP during the setup of a consumer(See Executor Module) is needed to give
  the consumer some time to establish the connection and build the queues before
  sending any messages.
  """
  use ExUnit.Case
  alias Support
  alias Support.MessageTrace

  defmodule FailConsumer do
    use Tackle.Consumer,
      rabbitmq_url: "amqp://localhost",
      remote_exchange: "ex-tackle.test-exchange",
      routing_key: "test-messages",
      service: "ex-tackle.connection-errors-service",
      connection_id: :ack_fail,
      retry_limit: 0

    def handle_message(message) do
      message |> MessageTrace.save("connection-errors")

      Tackle.Connection.get_all()
      |> Keyword.get(:ack_fail)
      |> Map.get(:pid)
      |> Process.exit(:kill)

      :ok
    end
  end

  @publish_options %{
    rabbitmq_url: "amqp://localhost",
    exchange: "ex-tackle.test-exchange",
    routing_key: "test-messages"
  }
  @timeout 100

  setup do
    Support.cleanup!(FailConsumer)
    MessageTrace.clear("connection-errors")
    :timer.sleep(@timeout)

    on_exit(fn ->
      Support.cleanup!(FailConsumer)
    end)

    :ok
  end

  test "connection dies" do
    # Start Consumer
    pid = start_supervised!(FailConsumer)
    assert Process.alive?(pid)
    :timer.sleep(@timeout)

    # Send message which kills connection
    Tackle.publish("Hi!", @publish_options)
    :timer.sleep(@timeout)

    # Assert consumer died
    refute Process.alive?(pid)
    assert MessageTrace.content("connection-errors") == "Hi!"
  end
end
