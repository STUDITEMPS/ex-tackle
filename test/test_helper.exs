defmodule Support do
  @rabbitmq_url Application.compile_env(:tackle, :rabbitmq_url)

  defmodule RabbitmqAPI do
    use Tesla
    @user Application.compile_env(:tackle, :rabbitmq_user)
    @password Application.compile_env(:tackle, :rabbitmq_password)
    @host Application.compile_env(:tackle, :rabbitmq_host)
    @token "#{@user}:#{@password}" |> Base.encode64()

    plug Tesla.Middleware.BaseUrl, "http://#{@host}:15672/api"
    plug Tesla.Middleware.Headers, [{"authorization", "Basic #{@token}"}]
    plug Tesla.Middleware.JSON

    def list_exchanges() do
      get!("/exchanges")
    end

    def list_queues() do
      get!("/queues")
    end
  end

  def rabbitmq_list_exchanges() do
    RabbitmqAPI.list_exchanges().body |> Enum.map(fn %{"name" => name} -> name end)
  end

  def rabbitmq_list_queues() do
    RabbitmqAPI.list_queues().body |> Enum.map(fn %{"name" => name} -> name end)
  end

  def cleanup!(consumer_module) do
    execute(fn channel ->
      topology = consumer_module.topology()
      Tackle.Consumer.Topology.cleanup!(channel, topology, _delete_remote_exchange = true)
    end)
  end

  def create_exchange(exchange_name) do
    execute(fn channel ->
      Tackle.Exchange.create(channel, exchange_name)
    end)
  end

  def delete_exchange(exchange_name) do
    execute(fn channel ->
      :ok = AMQP.Exchange.delete(channel, exchange_name)
    end)
  end

  def queue_status(queue_name) do
    {:ok, status} =
      execute(fn channel ->
        AMQP.Queue.status(channel, queue_name)
      end)

    status
  end

  def purge_queue(queue_name) do
    execute(fn channel ->
      AMQP.Queue.purge(channel, queue_name)
    end)
  end

  def delete_queue(queue_name) do
    execute(fn channel ->
      {:ok, _} = AMQP.Queue.delete(channel, queue_name)
    end)
  end

  def delete_all_queues(queue_name, delay \\ 1) do
    execute(fn channel ->
      AMQP.Queue.delete(channel, queue_name)
      AMQP.Queue.delete(channel, queue_name <> ".dead")
      AMQP.Queue.delete(channel, queue_name <> ".delay.#{delay}")
    end)
  end

  defp execute(fun) when is_function(fun, 1) do
    Tackle.execute(@rabbitmq_url, fun)
  end

  defmodule MessageTrace do
    # we should reimplement this with something nicer
    # like an in memory queue

    def save(message, trace_name) do
      File.write("/tmp/#{trace_name}", message, [:append])
    end

    def clear(trace_name) do
      File.rm_rf("/tmp/#{trace_name}")
    end

    def content(trace_name) do
      File.read!("/tmp/#{trace_name}")
    end
  end
end

ExUnit.start(trace: false, capture_log: true)
