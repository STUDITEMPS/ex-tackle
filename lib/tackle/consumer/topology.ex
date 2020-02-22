defmodule Tackle.Consumer.Topology do
  # one year in seconds
  @default_dead_message_ttl 604_800 * 52
  # in seconds
  @default_retry_delay 10
  @default_retry_limit 10

  @enforce_keys [
    :remote_exchange,
    :message_exchange,
    :routing_key,
    :queue,
    :delay_queue,
    :dead_queue,
    :retry_delay,
    :retry_limit,
    :dead_message_ttl
  ]
  defstruct [
    :remote_exchange,
    :message_exchange,
    :routing_key,
    :queue,
    :delay_queue,
    :dead_queue,
    :retry_delay,
    :retry_limit,
    :dead_message_ttl
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

  def setup!(channel, %__MODULE__{} = topology) do
    Tackle.Exchange.create(channel, topology.remote_exchange)
    Tackle.Exchange.create(channel, topology.message_exchange)

    Tackle.Queue.create_queue(channel, name: topology.queue)

    # FIXME: Keine Delay Queue anlegen, wenn retry Limit bei 0 liegt.
    Tackle.Queue.create_delay_queue(channel,
      name: topology.delay_queue,
      routing_key: topology.routing_key,
      delay: :timer.seconds(topology.retry_delay),
      republish_on: topology.message_exchange
    )

    Tackle.Queue.create_dead_queue(channel,
      name: topology.dead_queue,
      message_ttl: :timer.seconds(topology.dead_message_ttl)
    )

    Tackle.Exchange.bind_to_exchange(
      channel,
      topology.message_exchange,
      topology.remote_exchange,
      topology.routing_key
    )

    Tackle.Exchange.bind_to_queue(
      channel,
      topology.message_exchange,
      topology.queue,
      topology.routing_key
    )
  end

  def cleanup!(channel, %__MODULE__{} = topology, delete_remote_exchange \\ false) do
    AMQP.Queue.delete(channel, topology.queue)
    AMQP.Queue.delete(channel, topology.delay_queue)
    AMQP.Queue.delete(channel, topology.dead_queue)

    AMQP.Exchange.delete(channel, topology.message_exchange)

    if delete_remote_exchange do
      AMQP.Exchange.delete(channel, topology.remote_exchange)
    end
  end

  def new(
        service: service_name,
        remote_exchange: remote_exchange_name,
        routing_key: routing_key,
        retry: retry
      )
      when is_binary(service_name) and is_binary(remote_exchange_name) and is_binary(routing_key) and
             (is_list(retry) or is_boolean(retry)) do
    {retry_delay, retry_limit, dead_message_ttl} = extract_retry_options(retry)
    message_exchange = "#{service_name}.#{routing_key}"
    consume_from_queue = "#{service_name}.#{routing_key}"
    delay_queue = "#{consume_from_queue}.delay.#{retry_delay}"
    dead_queue = "#{consume_from_queue}.dead"

    %__MODULE__{
      routing_key: routing_key,
      remote_exchange: remote_exchange_name,
      message_exchange: message_exchange,
      queue: consume_from_queue,
      delay_queue: delay_queue,
      dead_queue: dead_queue,
      retry_delay: retry_delay,
      retry_limit: retry_limit,
      dead_message_ttl: dead_message_ttl
    }
  end

  # returns {retry_delay, retry_limit, dead_message_ttl} values
  defp extract_retry_options(from_options) do
    case from_options do
      false ->
        {0, 0, @default_dead_message_ttl}

      true ->
        {@default_retry_delay, @default_retry_limit, @default_dead_message_ttl}

      from_options when is_list(from_options) ->
        {Keyword.get(from_options, :delay) || @default_retry_delay,
         Keyword.get(from_options, :limit) || @default_retry_limit,
         Keyword.get(from_options, :dead_message_ttl) || @default_dead_message_ttl}
    end
  end

  defp retry_options_from(options) do
    case Map.get(options, :retry) do
      retry when is_boolean(retry) ->
        retry

      retry when is_list(retry) ->
        retry

      _ ->
        [
          delay: Map.get(options, :retry_delay),
          limit: Map.get(options, :retry_limit),
          dead_message_ttl: Map.get(options, :dead_message_ttl)
        ]
    end
  end
end
