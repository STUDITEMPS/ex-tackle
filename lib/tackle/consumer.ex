defmodule Tackle.Consumer do
  defmodule Behaviour do
    @type payload :: String.t()
    @type message_metadata :: map()
    @type error :: term()
    @type current_attempt :: integer()
    @type max_number_of_attemts :: integer()

    @callback handle_message(String.t()) :: any()
    @callback on_error(payload, message_metadata, error, current_attempt, max_number_of_attemts) ::
                any()
  end

  defmacro __using__(opts) do
    opts = opts || []

    quote location: :keep, generated: true do
      @opts unquote(opts)
      @name @opts[:name] || __MODULE__
      @behaviour Tackle.Consumer.Behaviour

      # Adds default handle and on_error functions
      @before_compile unquote(__MODULE__)

      def start_link(opts \\ []) do
        opts = Keyword.merge(@opts, opts)
        Tackle.Consumer.Executor.start_link(@name, _handler_module = __MODULE__, opts)
      end

      def child_spec(opts) do
        default = %{
          id: @name,
          start: {__MODULE__, :start_link, [opts]},
          restart: :permanent,
          type: :worker
        }

        Supervisor.child_spec(default, [])
      end
    end
  end

  defmacro __before_compile__(_env) do
    quote location: :keep, generated: true do
      def handle_message(message) do
        raise "Implement me"
      end

      defoverridable(handle_message: 1)

      def on_error(
            _payload,
            _message_metadata,
            _error_reason,
            _current_attempt,
            _max_number_of_attemts
          ),
          do: :ok

      defoverridable(on_error: 5)

      def retry_dead_messages(how_many \\ 1) do
        Tackle.Consumer.Executor.republish_dead_messages(@name, how_many)
      end
    end
  end
end
