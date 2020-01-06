defmodule Tackle.Consumer.Topology do
  @default_retry_delay 10
  @default_retry_limit 10

  @enforce_keys [
    :remote_exchange,
    :message_exchange,
    :routing_key,
    :consume_queue,
    :delay_queue,
    :dead_queue,
    :retry_delay,
    :retry_limit
  ]
  defstruct [
    :remote_exchange,
    :message_exchange,
    :routing_key,
    :consume_queue,
    :delay_queue,
    :dead_queue,
    :retry_delay,
    :retry_limit
  ]

  def from_options!(options) do
    options = Enum.into(options, %{})

    service = Map.fetch!(options, :service)
    routing_key = Map.fetch!(options, :routing_key)
    remote_exchange = Map.fetch!(options, :remote_exchange)
    retry = retry_options_from(options)

    new(
      service: service,
      remote_exchange: remote_exchange,
      routing_key: routing_key,
      retry: retry
    )
  end

  def new(
        service: service_name,
        remote_exchange: remote_exchange_name,
        routing_key: routing_key,
        retry: retry
      )
      when is_binary(service_name) and is_binary(remote_exchange_name) and is_binary(routing_key) and
             (is_list(retry) or is_boolean(retry)) do
    {retry_delay, retry_limit} = retry_options(retry)
    message_exchange = "#{service_name}.#{routing_key}"
    consume_queue = "#{service_name}.#{routing_key}"
    delay_queue = "#{consume_queue}.delay.#{retry_delay}"
    dead_queue = "#{consume_queue}.dead"

    %__MODULE__{
      routing_key: routing_key,
      remote_exchange: remote_exchange_name,
      message_exchange: message_exchange,
      consume_queue: consume_queue,
      delay_queue: delay_queue,
      dead_queue: dead_queue,
      retry_delay: retry_delay,
      retry_limit: retry_limit
    }
  end

  # returns {retry_delay, retry_limit} values
  defp retry_options(from_options) do
    case from_options do
      false ->
        {0, 0}

      true ->
        {@default_retry_delay, @default_retry_limit}

      from_options when is_list(from_options) ->
        {Keyword.get(from_options, :delay) || @default_retry_delay,
         Keyword.get(from_options, :limit) || @default_retry_limit}
    end
  end

  defp retry_options_from(options) do
    case Map.get(options, :retry) do
      retry when is_boolean(retry) ->
        retry

      retry when is_list(retry) ->
        retry

      _ ->
        [delay: Map.get(options, :retry_delay), limit: Map.get(options, :retry_limit)]
    end
  end
end
