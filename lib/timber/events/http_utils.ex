defmodule Timber.Events.HTTPUtils do
  @moduledoc false

  @doc false
  # Constructs a full path from the given parts
  def full_path(path, query_string) do
    %URI{path: path, query: query_string}
    |> URI.to_string()
  end

  @doc false
  # Constructs a full path from the given parts
  def full_url(scheme, host, path, port, query_string) do
    %URI{scheme: scheme, host: host, path: path, port: port, query: query_string}
    |> URI.to_string()
  end

  @doc false
  # Normalizes a URL into a Keyword.t that maps to our HTTP event fields.
  def normalize_url(url) when is_binary(url) do
    uri = URI.parse(url)
    [
      host: uri.authority,
      path: uri.path,
      port: uri.port,
      query_string: uri.query,
      scheme: uri.scheme
    ]
  end
  def normalize_url(_url), do: []

  @doc false
  # Normalizes HTTP methods into a value expected by the Timber API.
  def normalize_method(method) when is_atom(method) do
    method
    |> Atom.to_string()
    |> normalize_method()
  end
  def normalize_method(method) when is_binary(method), do: String.upcase(method)
  def normalize_method(method), do: method

  @doc false
  # Normalizes HTTP headers into a structure expected by the Timber API.
  def normalize_headers(headers, allowed_keys) when is_list(headers) do
    headers
    |> List.flatten()
    |> Enum.into(%{})
    |> normalize_headers(allowed_keys)
  end
  def normalize_headers(headers, allowed_keys) when is_map(headers) do
    headers
    |> Enum.filter_map(fn {k,_v} -> k in allowed_keys end, &header_to_keyword/1)
    |> Enum.into(%{})
  end
  def normalize_headers(headers), do: headers

  @doc false
  # Converts header key value pairs into a structure expected by the Timber API.
  @spec header_to_keyword({String.t, String.t}) :: {atom, String.t}
  defp header_to_keyword({"x-request-id", id}), do: {:request_id, id}
  defp header_to_keyword({name, value}) do
    atom_name =
      name
      |> String.replace("-", "_")
      |> String.to_existing_atom()
    {atom_name, value}
  end
end