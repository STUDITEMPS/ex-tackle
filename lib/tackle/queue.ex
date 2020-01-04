defmodule Tackle.Queue do
  require Logger
  alias Tackle.Consumer.Topology

  # one year in milliseconds
  @dead_letter_timeout 604_800_000 * 52

  def create_consume_queue(channel, %Topology{consume_queue: queue_name}) do
    Logger.debug("Creating queue '#{queue_name}'")

    {:ok, _queue_status} = AMQP.Queue.declare(channel, queue_name, durable: true)

    queue_name
  end

  def create_delay_queue(_channel, %Topology{retry_limit: 0}), do: :ok

  def create_delay_queue(channel, %Topology{} = topology) do
    queue_name = topology.delay_queue
    Logger.debug("Creating delay queue '#{queue_name}'")

    AMQP.Queue.declare(
      channel,
      queue_name,
      durable: true,
      arguments: [
        {"x-dead-letter-exchange", :longstr, topology.message_exchange},
        {"x-dead-letter-routing-key", :longstr, topology.routing_key},
        {"x-message-ttl", :long, :timer.seconds(topology.retry_delay)}
      ]
    )

    queue_name
  end

  def create_dead_queue(channel, %Topology{dead_queue: queue_name}) do
    Logger.debug("Creating dead queue '#{queue_name}'")

    AMQP.Queue.declare(
      channel,
      queue_name,
      durable: true,
      arguments: [
        {"x-message-ttl", :long, @dead_letter_timeout}
      ]
    )

    queue_name
  end
end
