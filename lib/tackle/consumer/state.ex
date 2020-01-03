defmodule Tackle.Consumer.State do
  @enforce_keys [
    :handler,
    :rabbitmq_url,
    :routing_key,
    :service,
    :remote_exchange,
    :connection_id,
    :prefetch_count,
    :retry_delay,
    :retry_limit,
    :handler
  ]
  defstruct [
    :handler,
    :routing_key,
    :channel,
    :service,
    :service_exchange,
    :remote_exchange,
    :consume_queue,
    :delay_queue,
    :dead_queue,
    rabbitmq_url: "amqp://localhost",
    connection_id: :default,
    prefetch_count: 1,
    # in seconds
    retry_delay: 10,
    retry_limit: 10
  ]

  def configure!(options) do
    options = default_options() |> Map.merge(options) |> validate!()
    struct(__MODULE__, options)
  end

  def started(%__MODULE__{} = me,
        channel: channel,
        service_exchange: service_exchange,
        consume_queue: consume_queue,
        delay_queue: delay_queue,
        dead_queue: dead_queue
      ) do
    %{
      me
      | channel: channel,
        service_exchange: service_exchange,
        consume_queue: consume_queue,
        delay_queue: delay_queue,
        dead_queue: dead_queue
    }
  end

  defp default_options do
    %{
      connection_id: :default,
      prefetch_count: 1,
      # in seconds
      retry_delay: 10,
      retry_limit: 10
    }
  end

  defp validate!(%{} = options) do
    options
    |> validate_handler!()
    |> validate_rabbitmq_url!()
    |> validate_service!()
    |> validate_routing_key!()
    |> validate_remote_exchange!()
  end

  def validate_handler!(options) do
    unless options[:handler] do
      raise ArgumentError, "`handler` option required"
    end

    options
  end

  defp validate_rabbitmq_url!(%{url: rabbitmq_url} = options) do
    IO.warn(
      "Setting RabbitMQ url using `url` option is deprecated. Use `rabbitmq_url` option instead",
      Macro.Env.stacktrace(__ENV__)
    )

    options
    |> Map.put_new(:rabbitmq_url, rabbitmq_url)
    |> Map.delete(:url)
  end

  defp validate_rabbitmq_url!(options), do: options

  defp validate_service!(options) do
    unless options[:service] do
      raise ArgumentError, "`service` option required"
    end

    options
  end

  defp validate_routing_key!(options) do
    unless options[:routing_key] do
      raise ArgumentError, "`routing_key` option required"
    end

    options
  end

  defp validate_remote_exchange!(%{exchange: remote_exchange} = options) do
    IO.warn(
      "Setting Remote Exchange using `exchange` option is deprecated. Use `remote_exchange` option instead",
      Macro.Env.stacktrace(__ENV__)
    )

    options
    |> Map.put_new(:remote_exchange, remote_exchange)
    |> Map.delete(:exchange)
    |> validate_remote_exchange!()
  end

  defp validate_remote_exchange!(options) do
    unless options[:remote_exchange] do
      raise ArgumentError, "`exchange` option required"
    end

    options
  end
end
