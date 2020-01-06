defmodule Tackle.Channel do
  @default_prefetch_count 1

  def create(connection, prefetch_count \\ @default_prefetch_count) do
    {:ok, channel} = AMQP.Channel.open(connection)

    :ok = AMQP.Basic.qos(channel, prefetch_count: prefetch_count)

    channel
  end

  def close(channel) do
    :ok = AMQP.Channel.close(channel)
  end
end
