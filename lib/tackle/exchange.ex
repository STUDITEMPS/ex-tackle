defmodule Tackle.Exchange do
  require Logger

  # FIXME: let the user configure this in every situation: consumer, publisher and so on.
  # Do not save the configuration in a module variable. Each change would then require to
  # recompile the deps
  @default_exchange_type Application.compile_env(:tackle, :exchange_type, :direct)

  def create(channel, name, type \\ @default_exchange_type) do
    :ok = AMQP.Exchange.declare(channel, name, type, durable: true)
  end

  def bind_to_exchange(channel, destination, source, routing_key) do
    Logger.debug("Binding '#{destination}' to '#{source}' with '#{routing_key}' routing key")
    :ok = AMQP.Exchange.bind(channel, destination, source, routing_key: routing_key)
  end

  def bind_to_queue(channel, exchange, queue, routing_key) do
    Logger.debug("Binding '#{queue}' to '#{exchange}' with '#{routing_key}' routing key")
    :ok = AMQP.Queue.bind(channel, queue, exchange, routing_key: routing_key)
  end
end
