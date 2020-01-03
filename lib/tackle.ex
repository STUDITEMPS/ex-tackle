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

  def publish(message, options) when is_binary(message) do
    options = deprecate_old_options(options)
    rabbitmq_url = options[:rabbitmq_url]
    remote_exchange = options[:remote_exchange]
    routing_key = options[:routing_key]

    Logger.debug("Connecting to '#{Tackle.DebugHelper.safe_uri(rabbitmq_url)}'")
    {:ok, connection} = AMQP.Connection.open(rabbitmq_url)
    channel = Tackle.Channel.create(connection)

    Logger.debug("Declaring an exchange '#{remote_exchange}'")

    Tackle.Exchange.create_remote_exchange(channel, remote_exchange)

    AMQP.Basic.publish(channel, remote_exchange, routing_key, message, persistent: true)

    AMQP.Channel.close(channel)
    AMQP.Connection.close(connection)
  end

  def republish(options) do
    options = deprecate_old_options(options)

    rabbitmq_url = options[:rabbitmq_url]
    queue = options[:queue]
    remote_exchange = options[:remote_exchange]
    routing_key = options[:routing_key]
    count = options[:count] || 1

    Tackle.Republisher.republish(rabbitmq_url, queue, remote_exchange, routing_key, count)
  end

  defp deprecate_old_options(options) do
    options =
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

    options =
      if options[:exchange] do
        IO.warn(
          "Setting Remote Exchange using `exchange` option is deprecated. Use `remote_exchange` option instead",
          Macro.Env.stacktrace(__ENV__)
        )

        options
        |> Map.put_new(:remote_exchange, options[:exchange])
        |> Map.delete(:exchange)
      else
        options
      end

    options
  end
end
