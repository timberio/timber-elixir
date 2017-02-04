defmodule Timber.Events.ExceptionEvent do
  @moduledoc """
  The `ExceptionEvent` is used to track exceptions.

  Timber can automatically keep track of errors reported by the VM by hooking
  into the SASL reporting system to collect exception information, so it should
  be unnecessary to track exceptions manually. See `Timber.Integrations.ErrorLogger` for
  more details.
  """

  alias Timber.Utils.Module, as: UtilsModule

  @type stacktrace_entry :: {
    module,
    atom,
    arity,
    [file: IO.chardata, line: non_neg_integer] | []
  }

  @type backtrace_entry :: %{
    function: String.t,
    file: String.t | nil,
    line: non_neg_integer | nil
  }

  @type t :: %__MODULE__{
    backtrace: [backtrace_entry] | [],
    name: String.t,
    message: String.t,
  }

  @enforce_keys [:backtrace, :name, :message]
  defstruct [:backtrace, :name, :message]

  @doc """
  Builds a new struct taking care to normalize data into a valid state. This should
  be used, where possible, instead of creating the struct directly.
  """
  @spec new(atom | Exception.t, [stacktrace_entry] | []) :: t
  def new(error, stacktrace \\ []) do
    {name, message} = transform_error(error)
    backtrace = Enum.map(stacktrace, &transform_stacktrace/1)
    %__MODULE__{
      name: name,
      message: message,
      backtrace: backtrace
    }
  end

  @doc """
  Message to be used when logging.
  """
  @spec message(t) :: IO.chardata
  def message(%__MODULE__{name: name, message: message}),
    do: [name, ?:, ?\s, message]

  defp transform_error(error) when is_atom(error) do
    name = inspect(error)
    {name, name}
  end

  defp transform_error(%{__exception__: true, __struct__: module} = error) do
    name = UtilsModule.name(module)
    msg = Exception.message(error)
    {name, msg}
  end

  defp transform_stacktrace({module, function_name, arity, fileinfo}) do
    module_name = UtilsModule.name(module)

    function_name = Atom.to_string(function_name)

    function = to_string([module_name, ?., function_name, ?/, to_string(arity)])

    backtrace_entry = %{
      function: function
    }

    case file_information(fileinfo) do
      {filename, lineno} ->
        backtrace_entry
        |> Map.put(:file, filename)
        |> Map.put(:line, lineno)
      _ ->
        backtrace_entry
    end
  end

  defp file_information([]) do
    :no_file
  end

  defp file_information(fileinfo) do
    filename = Keyword.get(fileinfo, :file)
    lineno = Keyword.get(fileinfo, :line)

    if filename && lineno do
      {to_string(filename), to_string(lineno)}
    else
      :bad_descriptor
    end
  end
end
