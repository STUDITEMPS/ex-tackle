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
    options = Map.put_new(options, :topology, Tackle.Consumer.Topology.from_options!(options))

    struct(__MODULE__, options)
  end

  def started(%__MODULE__{} = me, channel: channel) do
    %{me | channel: channel}
  end
end
