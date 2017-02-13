defmodule Timber.Transports.HTTP.Client do
  @moduledoc """
  Behavior for custom HTTP clients. If you opt not to use the default Timber HTTP client
  (`Timber.Transports.HTTP.HackneyClient`) you can define your own here.

  ## Example

  ```elixir
  defmodule MyHTTPClient do
    alias Timber.Transports.HTTP.Client

    @behaviour Client

    @spec request(Client.method, Client.url, Client.headers, Client.body, Client.options) ::
      {:ok, Client.status, Client.Headers, Client.body} | {:error, any()}
    def request(method, url, headers, body, opts) do
      # make request here
    end
  end
  ```

  Then specify it in your configuration:

  ```elixir
  config :timber, :http_transport, http_client: MyHTTPClient
  ```
  """

  @type body :: IO.chardata
  @type headers :: map
  @type method :: atom
  @type status :: pos_integer
  @type url :: String.t
  @type result :: {:ok, reference} | {:error, atom}

  @callback start_link :: {:ok, reference} | {:error, any}
  @callback async_request(method, url, headers, body) :: result
  @callback done?(reference, any) :: boolean
end