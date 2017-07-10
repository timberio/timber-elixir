defprotocol Timber.Contextable do
  @moduledoc """
  Converts a data structure into a `Timber.Context.t`. This is called on any data structure passed
  in the `Timber.add_context/1` function.

  For example, this protocol is how we're able to support `Keyword.t` types:

  ```elixir
  Timber.add_context(build: %{version: "1.0"})
  ```

  This is achieved by:

  ```elixir
  defimpl Timber.Contextable, for: Map do
    def to_context(map) when map_size(map) == 1 do
      [type] = Map.keys(map)
      [data] = Map.values(map)
      %Timber.Contexts.CustomContext{
        type: type,
        data: data
      }
    end
  end
  ```

  ## What about custom contexts and structs?

  We recommend defining a struct and calling `use Timber.Contexts.CustomContext` in that module.
  This takes care of everything automatically. See `Timber.Contexts.CustomContext` for examples.
  """

  @doc """
  Converts the data structure into a `Timber.Event.t`.
  """
  @spec to_context(any) :: Timber.Context.t
  def to_context(data)
end

defimpl Timber.Contextable, for: Timber.Contexts.CustomContext do
  def to_context(context), do: context
end

defimpl Timber.Contextable, for: Timber.Contexts.HTTPContext do
  def to_context(context), do: context
end

defimpl Timber.Contextable, for: Timber.Contexts.JobContext do
  def to_context(context), do: context
end

defimpl Timber.Contextable, for: Timber.Contexts.OrganizationContext do
  def to_context(context), do: context
end

defimpl Timber.Contextable, for: Timber.Contexts.RuntimeContext do
  def to_context(context), do: context
end

defimpl Timber.Contextable, for: Timber.Contexts.SessionContext do
  def to_context(context), do: context
end

defimpl Timber.Contextable, for: Timber.Contexts.SystemContext do
  def to_context(context), do: context
end

defimpl Timber.Contextable, for: Timber.Contexts.UserContext do
  def to_context(context), do: context
end

defimpl Timber.Contextable, for: List do
  def to_context(list) do
    if Keyword.keyword?(list) do
      list
      |> Enum.into(%{})
      |> Timber.Contextable.to_context()
    else
      raise "The provided list is not a Keyword.t and therefore cannot be converted " <>
        "to a Timber context"
    end
  end
end

defimpl Timber.Contextable, for: Map do
  def to_context(%{type: type, data: data}) do
    %Timber.Contexts.CustomContext{
      type: type,
      data: data
    }
  end

  def to_context(map) when map_size(map) == 1 do
    [type] = Map.keys(map)
    [data] = Map.values(map)
    %Timber.Contexts.CustomContext{
      type: type,
      data: data
    }
  end
end