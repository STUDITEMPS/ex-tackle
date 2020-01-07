defmodule Tackle.Queue do
  require Logger

  def create_queue(channel, name: name) do
    create_queue(channel, name: name, options: [])
  end

  def create_queue(channel, name: name, options: options) when is_list(options) do
    options = Keyword.put_new(options, :durable, true)

    Logger.debug("Creating queue '#{name}'")

    {:ok, _queue_status} = AMQP.Queue.declare(channel, name, options)
  end

  def create_delay_queue(channel,
        name: name,
        routing_key: routing_key,
        delay: delay_in_milliseconds,
        republish_on: exchange
      ) do
    create_queue(channel,
      name: name,
      options: [
        durable: true,
        arguments: [
          {"x-dead-letter-exchange", :longstr, exchange},
          {"x-dead-letter-routing-key", :longstr, routing_key},
          {"x-message-ttl", :long, delay_in_milliseconds}
        ]
      ]
    )
  end

  def create_dead_queue(channel, name: name, message_ttl: message_ttl) do
    create_queue(channel,
      name: name,
      options: [
        durable: true,
        arguments: [
          {"x-message-ttl", :long, message_ttl}
        ]
      ]
    )
  end
end
