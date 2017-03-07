defmodule Timber.Installer.FakeFileContents do
  def default_config_contents do
    """
    # This file is responsible for configuring your application
    # and its dependencies with the aid of the Mix.Config module.
    #
    # This configuration file is loaded before any dependency and
    # is restricted to this project.
    use Mix.Config

    # General application configuration
    config :elixir_phoenix_example_app,
      ecto_repos: [ElixirPhoenixExampleApp.Repo]

    # Configures the endpoint
    config :elixir_phoenix_example_app, ElixirPhoenixExampleApp.Endpoint,
      url: [host: "localhost"],
      secret_key_base: "PIW+jnFP5piAAlp679uxb3Px1YD2pA7IQXqnQz67AC/tZXiAoqMpjjJTEFZ6RQXp",
      render_errors: [view: ElixirPhoenixExampleApp.ErrorView, accepts: ~w(html json)],
      pubsub: [name: ElixirPhoenixExampleApp.PubSub,
               adapter: Phoenix.PubSub.PG2],
      instrumenters: [Timber.Integrations.PhoenixInstrumenter]

    # Configures Elixir's Logger
     config :logger, :console,
       format: "$time $metadata[$level] $message\n",
       metadata: [:request_id]

    # Import environment specific config. This must remain at the bottom
    # of this file so it overrides the configuration defined above.
    import_config "#{Mix.env}.exs"
    """
  end

  def default_endpoint_contents do
    """
    defmodule ElixirPhoenixExampleApp.Endpoint do
      use Phoenix.Endpoint, otp_app: :elixir_phoenix_example_app

      socket "/socket", ElixirPhoenixExampleApp.UserSocket

      # Serve at "/" the static files from "priv/static" directory.
      #
      # You should set gzip to true if you are running phoenix.digest
      # when deploying your static files in production.
      plug Plug.Static,
        at: "/", from: :elixir_phoenix_example_app, gzip: false,
        only: ~w(css fonts images js favicon.ico robots.txt)

      # Code reloading can be explicitly enabled under the
      # :code_reloader configuration of your endpoint.
      if code_reloading? do
        socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
        plug Phoenix.LiveReloader
        plug Phoenix.CodeReloader
      end

      plug Plug.RequestId

      plug Plug.Parsers,
        parsers: [:urlencoded, :multipart, :json],
        pass: ["*/*"],
        json_decoder: Poison

      plug Plug.MethodOverride
      plug Plug.Head

      # The session will be stored in the cookie and signed,
      # this means its contents can be read but not tampered with.
      # Set :encryption_salt if you would also like to encrypt it.
      plug Plug.Session,
        store: :cookie,
        key: "_elixir_phoenix_example_app_key",
        signing_salt: "abfd232"

      plug ElixirPhoenixExampleApp.Router
    end
    """
  end

  def default_web_contents do
    """
    defmodule ElixirPhoenixExampleApp.Web do
      def model do
        quote do
          use Ecto.Schema

          import Ecto
          import Ecto.Changeset
          import Ecto.Query
        end
      end

      def controller do
        quote do
          use Phoenix.Controller

          alias ElixirPhoenixExampleApp.Repo
          import Ecto
          import Ecto.Query

          import ElixirPhoenixExampleApp.Router.Helpers
          import ElixirPhoenixExampleApp.Gettext
        end
      end

      def view do
        quote do
          use Phoenix.View, root: "web/templates"

          # Import convenience functions from controllers
          import Phoenix.Controller, only: [get_csrf_token: 0, get_flash: 2, view_module: 1]

          # Use all HTML functionality (forms, tags, etc)
          use Phoenix.HTML

          import ElixirPhoenixExampleApp.Router.Helpers
          import ElixirPhoenixExampleApp.ErrorHelpers
          import ElixirPhoenixExampleApp.Gettext
        end
      end

      def router do
        quote do
          use Phoenix.Router
        end
      end

      def channel do
        quote do
          use Phoenix.Channel

          alias ElixirPhoenixExampleApp.Repo
          import Ecto
          import Ecto.Query
          import ElixirPhoenixExampleApp.Gettext
        end
      end

      defmacro __using__(which) when is_atom(which) do
        apply(__MODULE__, which, [])
      end
    end
    """
  end

  def config_addition do
    """

    # Import Timber, structured logging
    import_config \"timber.exs\"
    """
  end

  def new_endpoint_contents do
    """
    defmodule ElixirPhoenixExampleApp.Endpoint do
      use Phoenix.Endpoint, otp_app: :elixir_phoenix_example_app

      socket "/socket", ElixirPhoenixExampleApp.UserSocket

      # Serve at "/" the static files from "priv/static" directory.
      #
      # You should set gzip to true if you are running phoenix.digest
      # when deploying your static files in production.
      plug Plug.Static,
        at: "/", from: :elixir_phoenix_example_app, gzip: false,
        only: ~w(css fonts images js favicon.ico robots.txt)

      # Code reloading can be explicitly enabled under the
      # :code_reloader configuration of your endpoint.
      if code_reloading? do
        socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
        plug Phoenix.LiveReloader
        plug Phoenix.CodeReloader
      end

      plug Plug.RequestId

      plug Plug.Parsers,
        parsers: [:urlencoded, :multipart, :json],
        pass: ["*/*"],
        json_decoder: Poison

      plug Plug.MethodOverride
      plug Plug.Head

      # The session will be stored in the cookie and signed,
      # this means its contents can be read but not tampered with.
      # Set :encryption_salt if you would also like to encrypt it.
      plug Plug.Session,
        store: :cookie,
        key: "_elixir_phoenix_example_app_key",
        signing_salt: "abfd232"

      # Add Timber plugs for capturing HTTP context and events
      plug Timber.Integrations.ContextPlug
      plug Timber.Integrations.EventPlug

      plug ElixirPhoenixExampleApp.Router
    end
    """
  end

  def new_web_contents do
    """
    defmodule ElixirPhoenixExampleApp.Web do
      def model do
        quote do
          use Ecto.Schema

          import Ecto
          import Ecto.Changeset
          import Ecto.Query
        end
      end

      def controller do
        quote do
          use Phoenix.Controller, log: false

          alias ElixirPhoenixExampleApp.Repo
          import Ecto
          import Ecto.Query

          import ElixirPhoenixExampleApp.Router.Helpers
          import ElixirPhoenixExampleApp.Gettext
        end
      end

      def view do
        quote do
          use Phoenix.View, root: "web/templates"

          # Import convenience functions from controllers
          import Phoenix.Controller, only: [get_csrf_token: 0, get_flash: 2, view_module: 1]

          # Use all HTML functionality (forms, tags, etc)
          use Phoenix.HTML

          import ElixirPhoenixExampleApp.Router.Helpers
          import ElixirPhoenixExampleApp.ErrorHelpers
          import ElixirPhoenixExampleApp.Gettext
        end
      end

      def router do
        quote do
          use Phoenix.Router
        end
      end

      def channel do
        quote do
          use Phoenix.Channel

          alias ElixirPhoenixExampleApp.Repo
          import Ecto
          import Ecto.Query
          import ElixirPhoenixExampleApp.Gettext
        end
      end

      defmacro __using__(which) when is_atom(which) do
        apply(__MODULE__, which, [])
      end
    end
    """
  end

  def timber_config_contents do
    """
    use Mix.Config

    # Get existing instruments so that we don't overwrite.
    instrumenters =
      Application.get_env(:timber_elixir, TimberElixir.Endpoint)
      |> Keyword.get(:instrumenters, [])

    # Add the Timber instrumenter
    new_instrumenters =
      [Timber.Integrations.PhoenixInstrumenter | instrumenters]
      |> Enum.uniq()

    # Update the instrumenters so that we can structure Phoenix logs
    config :timber_elixir, TimberElixir.Endpoint,
      instrumenters: new_instrumenters

    # Structure Ecto logs
    config :timber_elixir, TimberElixir.Repo,
      loggers: [{Timber.Integrations.EctoLogger, :log, [:info]}]

    # Use Timber as the logger backend
    # Feel free to add additional backends if you want to send you logs to multiple devices.
    config :logger,
      backends: [Timber.LoggerBackend]

    # Direct logs to STDOUT for Heroku. We'll use Heroku drains to deliver logs.
    config :timber,
      transport: Timber.Transports.IODevice

    # For dev / test environments, always log to STDOUt and format the logs properly
    if Mix.env() == :dev || Mix.env() == :test do
      config :timber, transport: Timber.Transports.IODevice

      config :timber, :io_device,
        colorize: true,
        format: :logfmt,
        print_timestamps: true,
        print_log_level: true,
        print_metadata: false # turn this on to view the additiional metadata
    end

    # Need help? Contact us at support@timber.io
    """
  end
end