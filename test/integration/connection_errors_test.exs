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

  defmodule AckFailConsumer do
    use Tackle.Consumer,
      rabbitmq_url: "amqp://localhost",
      remote_exchange: "test-exchange",
      routing_key: "test-messages",
      service: "connection-errors-service",
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

  defmodule DelayFailConsumer do
    use Tackle.Consumer,
      rabbitmq_url: "amqp://localhost",
      remote_exchange: "test-exchange",
      routing_key: "test-messages",
      service: "connection-errors-service",
      connection_id: :delay_fail,
      retry_delay: 1,
      retry_limit: 3

    def handle_message(message) do
      message |> MessageTrace.save("connection-errors")

      Tackle.Connection.get_all()
      |> Keyword.get(:delay_fail)
      |> Map.get(:pid)
      |> Process.exit(:kill)

      # exception
      raise ArgumentError
    end
  end

  defmodule DeadFailConsumer do
    use Tackle.Consumer,
      rabbitmq_url: "amqp://localhost",
      remote_exchange: "test-exchange",
      routing_key: "test-messages",
      service: "connection-errors-service",
      connection_id: :dead_fail,
      retry_limit: 0

    def handle_message(message) do
      message |> MessageTrace.save("connection-errors")

      Tackle.Connection.get_all()
      |> Keyword.get(:dead_fail)
      |> Map.get(:pid)
      |> Process.exit(:kill)

      # exception
      raise ArgumentError
    end
  end

  @publish_options %{
    rabbitmq_url: "amqp://localhost",
    exchange: "test-exchange",
    routing_key: "test-messages"
  }
  @timeout 10

  setup do
    MessageTrace.clear("connection-errors")

    :ok
  end

  test "connection is lost before ack is sent" do
    task =
      Task.async(fn ->
        {:ok, pid} = AckFailConsumer.start_link()
        pid
      end)

    pid = Task.await(task)

    Tackle.publish("Hi!", @publish_options)

    :timer.sleep(@timeout)
    refute Process.alive?(pid)
    assert MessageTrace.content("connection-errors") == "Hi!"
  end

  test "connection is lost while pushing message to delay queue" do
    task =
      Task.async(fn ->
        {:ok, pid} = DelayFailConsumer.start_link()
        pid
      end)

    pid = Task.await(task)

    Tackle.publish("Hi!", @publish_options)

    :timer.sleep(@timeout)

    assert MessageTrace.content("connection-errors") == "Hi!"

    refute Process.alive?(pid)
  end

  test "connection is lost while pushing message to dead queue" do
    task =
      Task.async(fn ->
        {:ok, pid} = DeadFailConsumer.start_link()
        pid
      end)

    pid = Task.await(task)

    Tackle.publish("Hi!", @publish_options)

    :timer.sleep(@timeout)

    assert MessageTrace.content("connection-errors") == "Hi!"

    refute Process.alive?(pid)
  end
end
