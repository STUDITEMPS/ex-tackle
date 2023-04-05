defmodule Tackle.Channel do
  @default_prefetch_count 1

  def create(connection, prefetch_count \\ @default_prefetch_count) do
    with {:ok, channel} <- AMQP.Channel.open(connection),
         :ok <- AMQP.Basic.qos(channel, prefetch_count: prefetch_count) do
      {:ok, channel}
    end
  end

  def create!(connection, prefetch_count \\ @default_prefetch_count) do
    {:ok, channel} = create(connection, prefetch_count)
    channel
  end

  def close(channel) do
    AMQP.Channel.close(channel)
  end

  def close!(channel) do
    :ok = close(channel)
  end
end
