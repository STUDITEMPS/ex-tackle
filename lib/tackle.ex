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
    options = options |> Enum.into(%{}) |> deprecate_old_options()

    rabbitmq_url = Map.fetch!(options, :rabbitmq_url)
    exchange = Map.fetch!(options, :exchange)
    routing_key = Map.fetch!(options, :routing_key)

    execute(rabbitmq_url, fn channel ->
      Tackle.Exchange.create(channel, exchange)
      AMQP.Basic.publish(channel, exchange, routing_key, message, persistent: true)
    end)
  end

  @doc false
  def execute(rabbitmq_url, fun) when is_binary(rabbitmq_url) and is_function(fun, 1) do
    Logger.debug("Connecting to '#{Tackle.DebugHelper.safe_uri(rabbitmq_url)}'")
    {:ok, connection} = AMQP.Connection.open(rabbitmq_url)
    {:ok, channel} = AMQP.Channel.open(connection)

    try do
      fun.(channel)
    after
      AMQP.Channel.close(channel)
      AMQP.Connection.close(connection)
    end
  end

  # Do we need deprecations? We are the only users of our fork! If not, just drop the support for
  # `:url` and for `:exchange` in consumer
  defp deprecate_old_options(options) do
    if options[:url] do
      IO.warn(
        "Setting RabbitMQ url using `url` option is deprecated. Use `rabbitmq_url` option instead",
        Macro.Env.stacktrace(__ENV__)
      )

      options
      |> Map.put_new(:rabbitmq_url, options[:url])
      |> Map.delete(:url)
    else
      options
    end
  end
end
