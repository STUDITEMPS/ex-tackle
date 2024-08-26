defmodule Tackle.Republisher do
  use AMQP
  require Logger

  def republish(rabbitmq_url, dead_queue_name, exchange, routing_key, count) do
    Tackle.execute(rabbitmq_url, :default, fn channel ->
      0..(count - 1)
      |> Enum.each(fn _ ->
        republish_one_message(channel, dead_queue_name, exchange, routing_key)
      end)
    end)
  end

  defp republish_one_message(channel, dead_queue_name, exchange, routing_key) do
    case AMQP.Basic.get(channel, dead_queue_name) do
      {:empty, _} ->
        Logger.debug("No messages to republish in '#{dead_queue_name}'")

      {:ok, message, %{delivery_tag: tag}} ->
        :ok = AMQP.Basic.publish(channel, exchange, routing_key, message, persistent: true)
        :ok = AMQP.Basic.ack(channel, tag)

        Logger.debug("Republished a message with delivery tag '#{tag}' to '#{dead_queue_name}'")
    end
  end
end
