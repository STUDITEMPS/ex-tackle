defmodule Tackle.Republisher do
  use AMQP
  require Logger

  def republish(rabbitmq_url, dead_queue_name, exchange, routing_key, count) do
    Tackle.execute(rabbitmq_url, fn channel ->
      0..(count - 1)
      |> Enum.each(fn index ->
        IO.write("(#{index}) ")

        republish_one_message(channel, dead_queue_name, exchange, routing_key)
      end)
    end)
  end

  defp republish_one_message(channel, dead_queue_name, exchange, routing_key) do
    IO.write("Fetching message... ")

    case AMQP.Basic.get(channel, dead_queue_name) do
      {:empty, _} ->
        IO.puts("no more messages")

      {:ok, message, %{delivery_tag: tag}} ->
        AMQP.Basic.publish(channel, exchange, routing_key, message, persistent: true)
        AMQP.Basic.ack(channel, tag)

        IO.puts("republished")
    end
  end
end
