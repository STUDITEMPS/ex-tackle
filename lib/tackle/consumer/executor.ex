defmodule Tackle.Consumer.Executor do
  # let genserver 1 sec for cleanup work
  use GenServer, shutdown: 1_000

  def start_link(name, handler_module, overrides) do
    overrides = Enum.into(overrides, %{})

    state = %{overrides | handler_module: handler_module, name: name}
    GenServer.start_link(__MODULE__, state, name: name)
  end

  def init(options) do
    options = Map.merge(default_options(), options)

    setup(options)
  end

  defp setup(options) do
    validate_options!(options)

    {:ok, channel} =
      setup_connection_channel(
        options.connection_id,
        options.rabbitmq_url,
        options.prefetch_count
      )
  end

  defp setup_connection_channel(connection_id, url, prefetch_count) do
    with {:ok, connection} <- Tackle.Connection.open(connection_id, url) do
      channel = Tackle.Channel.create(connection, prefetch_count)
      {:ok, channel}
    end
  end

  # TODO: implement me
  defp validate_options!(_options), do: :ok

  defp default_options do
    %{
      connection_id: :default,
      prefetch_count: 1,
      # in seconds
      retry_delay: 10,
      retry_limit: 10,
      rabbitmq_url: Application.get_env(:tackle, :rabbitmq_url),
      service: Application.get_env(:tackle, :service)
    }
  end
end
