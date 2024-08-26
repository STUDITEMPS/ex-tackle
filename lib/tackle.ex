defmodule Tackle do
  use Application

  require Logger

  @impl Application
  def start(_type, _args) do
    children = [
      Tackle.Connection
    ]

    opts = [strategy: :one_for_one, name: Tackle.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # FIXME: why do we use options here? We need all of them, so make them mandatory
  # FIXME: this function is too generic if you use `exchange` as the option. Generic publishing should be done
  # with the AMQP.Basic.publish function. Here, we should enforce the `tackle` behaviour which publishes all messages
  # over the applications own __service_exchange__. So rename the option name!!!
  def publish(message, options) when is_binary(message) do
    options = Enum.into(options, %{})

    rabbitmq_url = Map.fetch!(options, :rabbitmq_url)
    exchange = Map.fetch!(options, :exchange)
    routing_key = Map.fetch!(options, :routing_key)
    connection_name = Map.get(options, :publisher_connection_name, :default)

    execute(rabbitmq_url, connection_name, fn channel ->
      Tackle.Exchange.create(channel, exchange)
      AMQP.Basic.publish(channel, exchange, routing_key, message, persistent: true)
    end)
  end

  @doc false
  def execute(rabbitmq_url, fun) do
    execute(rabbitmq_url, :default, fun)
  end

  @doc false
  def execute(rabbitmq_url, :default, fun) when is_binary(rabbitmq_url) and is_function(fun, 1) do
    Logger.debug("Connecting to '#{Tackle.DebugHelper.safe_uri(rabbitmq_url)}'")
    {:ok, connection} = Tackle.Connection.open(rabbitmq_url)
    {:ok, channel} = AMQP.Channel.open(connection)

    try do
      fun.(channel)
    after
      Tackle.Connection.close(connection)
    end
  end

  @doc false
  def execute(rabbitmq_url, connection_name, fun)
      when is_binary(rabbitmq_url) and is_function(fun, 1) do
    Logger.debug("Connecting to '#{Tackle.DebugHelper.safe_uri(rabbitmq_url)}'")
    {:ok, connection} = Tackle.Connection.open(connection_name, rabbitmq_url)
    {:ok, channel} = AMQP.Channel.open(connection)

    try do
      fun.(channel)
    after
      Tackle.Channel.close(channel)
    end
  end
end
