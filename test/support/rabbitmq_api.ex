defmodule Support.RabbitmqAPI do
  use Tesla

  @user Application.compile_env(:tackle, :rabbitmq_user)
  @password Application.compile_env(:tackle, :rabbitmq_password)
  @host Application.compile_env(:tackle, :rabbitmq_host)
  @token "#{@user}:#{@password}" |> Base.encode64()

  plug(Tesla.Middleware.BaseUrl, "http://#{@host}:15672/api")
  plug(Tesla.Middleware.Headers, [{"authorization", "Basic #{@token}"}])
  plug(Tesla.Middleware.JSON)

  def list_exchanges() do
    get!("/exchanges")
  end

  def list_queues() do
    get!("/queues")
  end
end
