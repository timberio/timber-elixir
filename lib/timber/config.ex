defmodule Timber.Config do
  @env_key :timber

  @doc """
  Your Timber application API key. This can be obtained after you create your
  application in https://app.timber.io

  # Example

  ```elixir
  config :timber, :api_key, "abcd1234"
  ```
  """
  def api_key, do: Application.get_env(@env_key, :api_key)

  @doc """
  Change the name of the `Logger` metadata key that Timber uses for events.
  By default, this is `:event`

  # Example

  ```elixir
  config :timber, :event_key, :timber_event
  Logger.info("test", timber_event: my_event)
  ```
  """
  def event_key, do: Application.get_env(@env_key, :event_key, :event)

  @doc """
  Configuration for the `:body` size limit in the `Timber.Events.HTTP*` events.
  Bodies that exceed this limit will be truncated to this limit.

  Please take care with this value, increasing it too high can mean very large
  payloads and very high outgoing network activity.

  # Example

  ```elixir
  config :timber, :http_body_size_limit, 5000
  ```
  """
  def http_body_size_limit, do: Application.get_env(@env_key, :http_body_size_limit, 2000)

  @doc """
  Custom HTTP client to use for transmitting logs over HTTP. Timber comes packaged with a
  `:hackney` client. See `Timber.Transports.HTTP.HackneyClient`. If you do not want to use
  `:hackney` you can easily write your own client to handle log transport.

  # Example

  ```elixir
  config :timber, :http_client, MyCustomHTTPClient
  ```
  """
  def http_client!, do: Application.fetch_env!(@env_key, :http_client)

  @doc """
  Alternate URL for delivering logs. This is helpful if you want to use a proxy,
  for example.

  # Example

  ```elixir
  config :timber, :http_url, "https://123.123.123.123"
  ```
  """
  def http_url, do: Application.get_env(@env_key, :http_url)

  @doc """
  Specify a different JSON encoder function. Timber uses `Poison` by default.

  # Example

  ```elixir
  config :timber, :json_encoder, fn map -> encode(map) end
  ```
  """
  def json_encoder, do: Application.get_env(@env_key, :json_encoder, &Poison.encode_to_iodata!/1)

  @doc """
  Specify the log level that phoenix log lines write to. Such as template renders.

  # Example

  ```elixir
  config :timber, :instrumentation_level, :info
  ```
  """
  @spec phoenix_instrumentation_level(atom) :: atom
  def phoenix_instrumentation_level(default) do
    Application.get_env(@env_key, :instrumentation_level, default)
  end

  @doc """
  Gets the transport specificed in the :timber configuration. The default is
  `Timber.Transports.IODevice`.
  """
  def transport, do: Application.get_env(@env_key, :transport, Timber.Transports.IODevice)
end