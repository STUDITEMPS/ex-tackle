defmodule Tackle.Exchange do
  require Logger
  alias Tackle.Consumer.Topology

  @exchange_type Application.get_env(:tackle, :exchange_type, :direct)

  def create(channel, exchange_name) do
    :ok = AMQP.Exchange.declare(channel, exchange_name, @exchange_type, durable: true)

    exchange_name
  end

  def create_message_exchange(channel, %Topology{message_exchange: exchange_name}) do
    create(channel, exchange_name)
  end

  def create_remote_exchange(channel, %Topology{remote_exchange: exchange_name}) do
    create(channel, exchange_name)
  end

  def bind_message_exchange_to_remote(channel, %Topology{} = topology) do
    create_remote_exchange(channel, topology)

    Logger.debug(
      "Binding '#{topology.message_exchange}' to '#{topology.remote_exchange}' with '#{
        topology.routing_key
      }' routing key"
    )

    AMQP.Exchange.bind(channel, topology.message_exchange, topology.remote_exchange,
      routing_key: topology.routing_key
    )
  end

  def bind_message_exchange_to_consume_queue(channel, %Topology{} = topology) do
    Logger.debug(
      "Binding '#{topology.consume_queue}' to '#{topology.message_exchange}' with '#{
        topology.routing_key
      }' routing key"
    )

    AMQP.Queue.bind(channel, topology.consume_queue, topology.message_exchange,
      routing_key: topology.routing_key
    )
  end
end
