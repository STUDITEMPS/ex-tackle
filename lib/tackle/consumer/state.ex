defmodule Tackle.Consumer.State do
  @enforce_keys [
    :handler,
    :topology,
    :rabbitmq_url,
    :connection_id,
    :prefetch_count
  ]
  defstruct [
    :handler,
    :topology,
    :channel,
    :rabbitmq_url,
    connection_id: :default,
    prefetch_count: 1
  ]

  def configure!(options) do
    options =
      options
      |> validate_rabbitmq_url()
      |> Map.put_new(:topology, Tackle.Consumer.Topology.from_options!(options))

    struct(__MODULE__, options)
  end

  def started(%__MODULE__{} = me, channel: channel) do
    %{me | channel: channel}
  end

  defp validate_rabbitmq_url(%{url: rabbitmq_url} = options) do
    IO.warn(
      "Setting RabbitMQ url using `url` option is deprecated. Use `rabbitmq_url` option instead",
      Macro.Env.stacktrace(__ENV__)
    )

    options
    |> Map.put_new(:rabbitmq_url, rabbitmq_url)
    |> Map.delete(:url)
  end

  defp validate_rabbitmq_url(options), do: options
end
