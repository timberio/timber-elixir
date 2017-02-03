defmodule Timber.Events.HTTPClientResponseEvent do
  @moduledoc """
  The `HTTPClientResponseEvent` tracks responses for *outgoing* HTTP *requests*. This gives you
  structured insight into communication with external services.

  See `Timber.Events.HTTPClientRequestEvent` for examples on track the entire HTTP request
  lifecycle.
  """

  alias Timber.Utils

  @enforce_keys [:status, :time_ms]
  defstruct [:bytes, :headers, :status, :time_ms]

  @type t :: %__MODULE__{
    bytes: non_neg_integer,
    headers: headers,
    status: pos_integer,
    time_ms: non_neg_integer
  }

  @type headers :: %{
    cache_control: String.t,
    content_disposition: String.t,
    content_length: non_neg_integer,
    content_type: String.t,
    location: String.t,
    request_id: String.t
  }

  @recognized_headers ~w(
    cache_control
    content_disposition
    content_length
    content_type
    location
    x-request-id
  )

  @doc """
  Builds a new struct taking care to normalize data into a valid state. This should
  be used, where possible, instead of creating the struct directly.
  """
  @spec new(Keyword.t) :: t
  def new(opts) do
    opts =
      opts
      |> Keyword.update(:headers, nil, fn headers ->
        Utils.normalize_headers(headers, @recognized_headers)
      end)
      |> Enum.filter(fn {_k,v} -> v != nil end)
    struct!(__MODULE__, opts)
  end

  @doc """
  Convenience methods for creating an event and getting the message at the same time.
  """
  @spec new_with_message(Keyword.t) :: {t, IO.chardata}
  def new_with_message(opts) do
    event = new(opts)
    {event, message(event)}
  end

  @doc """
  Message to be used when logging.
  """
  @spec message(t) :: IO.chardata
  def message(%__MODULE__{status: status, time_ms: time_ms, headers: %{request_id: request_id}})
    when is_binary(request_id),
    do: ["Outgoing HTTP response ", status, " in ", time_ms, "ms, ID ", request_id]
  def message(%__MODULE__{status: status, time_ms: time_ms}),
    do: ["Outgoing HTTP response ", status, " in ", time_ms, "ms"]
end
