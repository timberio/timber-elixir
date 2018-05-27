defmodule Timber.Stubbing do
  defmacro __using__(_) do
    quote do
      def start_link do
        Agent.start_link(fn -> %{} end, name: __MODULE__)
      end

      def reset do
        Agent.update(__MODULE__, fn _ -> %{} end)
      end

      defp add_function_call(name, args) do
        calls = get_function_calls(name)
        Agent.update(__MODULE__, &Map.put(&1, name, calls ++ [args]))
      end

      def get_function_calls(name) do
        Agent.get(__MODULE__, &Map.get(&1, name, []))
      end

      def stub(name, stub) do
        Agent.update(__MODULE__, &Map.put(&1, String.to_atom("#{name}_stub"), stub))
      end

      def get_stub(name) do
        Agent.get(__MODULE__, &Map.get(&1, String.to_atom("#{name}_stub")))
      end

      def get_stub!(name) do
        get_stub(name) || raise("No stub found for #{__MODULE__}.#{name}")
      end
    end
  end
end
