defmodule Support.RabbitmqApi do
  @user Application.compile_env(:tackle, :rabbitmq_user)
  @password Application.compile_env(:tackle, :rabbitmq_password)
  @host Application.compile_env(:tackle, :rabbitmq_host)
  @token "#{@user}:#{@password}" |> Base.encode64()

  defp middleware do
    [
      {Tesla.Middleware.BaseUrl, "http://#{@host}:15672/api"},
      {Tesla.Middleware.Headers, [{"authorization", "Basic #{@token}"}]},
      {Tesla.Middleware.JSON, []}
    ]
  end

  defp adapter do
    {Tesla.Adapter.Mint, []}
  end

  def client do
    Tesla.client(middleware(), adapter())
  end

  def list_exchanges() do
    client() |> Tesla.get!("/exchanges")
  end

  def list_queues() do
    client() |> Tesla.get!("/queues")
  end
end
