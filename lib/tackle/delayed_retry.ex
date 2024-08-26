defmodule Tackle.DelayedRetry do
  use AMQP
  require Logger

  def retry_count_from_headers(:undefined), do: 0
  def retry_count_from_headers([]), do: 0
  def retry_count_from_headers([{"retry_count", :long, count} | _tail]), do: count
  def retry_count_from_headers([_ | tail]), do: retry_count_from_headers(tail)

  def publish(rabbitmq_url, queue, payload, message_options) do
    Tackle.execute(rabbitmq_url, :default, fn channel ->
      AMQP.Basic.publish(channel, "", queue, payload, message_options)
    end)
  end
end
