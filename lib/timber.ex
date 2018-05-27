defmodule Timber do
  @moduledoc """
  The functions in this module are high level convenience functions instended to define
  the broader / public API of the Timber library. It is recommended to use these functions
  instead of their deeper counterparts.
  """

  use Application

  alias Timber.Context
  alias Timber.LocalContext
  alias Timber.GlobalContext

  @typedoc """
  The target context to perform the operation.

    - `:global` - This stores the context at a global level, meaning
      it will be present on every log line, regardless of which process
      generates the log line.
    - `:local` - This stores the context in the Logger Metadata which
      is local to the process
  """
  @type context_location :: :local | :global

  @doc """
  Adds Timber context to the current process

  See `add_context/2`
  """
  @spec add_context(Context.element()) :: :ok
  def add_context(data, location \\ :local)

  @doc """
  Adds context which will be included on log entries

  The second parameter indicates where you want the context to be
  stored. See `context_location` for more details.
  """
  @spec add_context(Context.element(), context_location) :: :ok
  def add_context(data, :local) do
    LocalContext.add(data)
  end

  def add_context(data, :global) do
    GlobalContext.add(data)
  end

  @doc """
  Removes a key from Timber context on the current process.

  See `remove_context_key/2`
  """
  @spec remove_context_key(atom) :: :ok
  def remove_context_key(key, location \\ :local)

  @doc """
  Removes a context key.

  The second parameter indicates which context you want the key to be removed from.
  """
  @spec remove_context_key(atom, context_location) :: :ok
  def remove_context_key(key, :local) do
    LocalContext.remove_key(key)
  end

  def remove_context_key(key, :global) do
    GlobalContext.remove_key(key)
  end

  @doc """
  Used to time runtime execution. For example, when timing a `Timber.Events.HTTPResponseEvent`:

  ```elixir
  timer = Timber.start_timer()
  # .... make request
  time_ms = Timber.duration_ms(timer)
  event = HTTPResponseEvent.new(status: 200, time_ms: time_ms)
  message = HTTPResponseEvent.message(event)
  Logger.info(message, event: event)
  ```

  """
  defdelegate start_timer, to: Timber.Timer, as: :start

  @doc """
  Captures the duration in fractional milliseconds since the timer was started. See
  `start_timer/0`.
  """
  defdelegate duration_ms(timer), to: Timber.Timer

  @doc false
  def debug(message_fun) do
    Timber.Config.debug_io_device()
    |> debug(message_fun)
  end

  @doc false
  def debug(nil, _message_fun) do
    false
  end

  def debug(io_device, message_fun) when is_function(message_fun) do
    IO.write(io_device, message_fun.())
  end

  @doc false
  # Handles the application callback start/2
  #
  # Starts an empty supervisor in order to comply with callback expectations
  #
  # This is the function that starts up the error logger listener
  #
  def start(_type, _opts) do
    import Supervisor.Spec, warn: false

    # Prepare the Phoenix instrumentation blacklist before we finish
    # starting
    Timber.Integrations.PhoenixInstrumenter.get_unparsed_blacklist()
    |> Timber.Integrations.PhoenixInstrumenter.parse_blacklist()
    |> Timber.Integrations.PhoenixInstrumenter.put_parsed_blacklist()

    children = []

    if Timber.Config.disable_tty?() do
      :error_logger.delete_report_handler(:error_logger_tty_h)
    end

    opts = [strategy: :one_for_one, name: Timber.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
