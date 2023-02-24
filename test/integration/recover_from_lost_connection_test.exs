defmodule Tackle.RecoverFromLostConnectionTest do
  @moduledoc """
  Consumer should be restarted if the connection is lost.
  """
  use ExUnit.Case
  require Support

  defmodule ConnectionLostConsumer do
    @rabbitmq_url Application.compile_env(:tackle, :rabbitmq_url)

    use Tackle.Consumer,
      rabbitmq_url: @rabbitmq_url,
      remote_exchange: "ex-tackle.test-exchange",
      routing_key: "test-messages",
      service: "ex-tackle.connection-lost-service",
      connection_id: :ex_tackle,
      retry_limit: 0,
      reconnect_interval: 10

    def handle_message(message) do
      Application.put_env(:tackle, :connection_lost_consumer_message, message)

      :ok
    end
  end

  @publish_options %{
    rabbitmq_url: Application.compile_env(:tackle, :rabbitmq_url),
    exchange: "ex-tackle.test-exchange",
    routing_key: "test-messages"
  }

  setup do
    Support.cleanup!(ConnectionLostConsumer)

    on_exit(fn ->
      Support.cleanup!(ConnectionLostConsumer)
    end)

    :ok
  end

  test "recovers if channel gets lost" do
    # Start Consumer
    pid = Support.start_consumer!(ConnectionLostConsumer)

    # Check the consumption is working
    Tackle.publish("Initial message", @publish_options)

    Support.wait_until(5_000, fn ->
      assert Application.get_env(:tackle, :connection_lost_consumer_message) == "Initial message"
    end)

    # Kill channel
    %{channel: channel} = :sys.get_state(pid)
    Process.exit(channel.pid, :something_went_wrong)

    # assert reconnect
    Support.wait_until(fn ->
      %{channel: channel} = :sys.get_state(pid)
      assert Process.alive?(channel.pid)
      assert Process.alive?(channel.conn.pid)
    end)

    # Assert consumption is resumed
    Tackle.publish("After connect message", @publish_options)

    Support.wait_until(fn ->
      assert Application.get_env(:tackle, :connection_lost_consumer_message) ==
               "After connect message"
    end)
  end
end
