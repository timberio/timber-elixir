defmodule Mix.Tasks.Timber.Install do
  @moduledoc false

  use Mix.Task

  alias __MODULE__.{API, Application, ConfigFile, EndpointFile, IOHelper, Messages, PathHelper,
    WebFile}
  alias Mix.Tasks.Timber.Install.HTTPClient.InvalidAPIKeyError
  alias Mix.Tasks.Timber.TestThePipes

  require Logger

  def run([]) do
    Messages.header()
    |> IOHelper.puts(:green)

    Messages.contact_and_support()
    |> IOHelper.puts()

    Messages.forgot_key()
    |> IOHelper.puts()
  end

  def run([api_key]) do
    api = API.new(api_key)

    try do
      :ok = API.start()

      API.event!(api, :started)

      if !Code.ensure_loaded?(:hackney) || !Code.ensure_loaded?(Plug) do
        """

        ^ These warnings are perfectly normal :) We include various libraries as *optional*
        depdencies, which logs these *expected* warnings. Now onto the good stuff...
        """
        |> IOHelper.puts(:yellow)

        Messages.separator()
        |> IOHelper.puts()
      end

      Messages.header()
      |> IOHelper.puts(:green)

      Messages.contact_and_support()
      |> IOHelper.puts()

      application = Application.new!(api)

      phoenix? = Code.ensure_loaded?(Phoenix)

      create_config_file!(application, api)
      link_config_file!(api)
      add_plugs!(phoenix?, api)
      disable_default_phoenix_logging!(phoenix?, api)
      install_user_context!(api)
      #install_http_client_context!(session_id, api_key)
      platform_install!(API.has_logs?(api), api, application)

      API.event!(api, :success)

      Messages.free_data()
      |> IOHelper.puts()

      """

      #{Messages.separator()}
      """
      |> IOHelper.puts()

      Messages.commit_and_deploy_reminder()
      |> IOHelper.puts()

      """
      #{Messages.separator()}
      """
      |> IOHelper.puts()

      collect_feedback(api)

    rescue
      e in InvalidAPIKeyError ->
        message = Exception.message(e)

        """
        #{String.duplicate("!", 80)}

        #{message}
        #{Messages.get_help()}
        """
        |> IOHelper.puts(:red)

      e ->
        message = Exception.message(e)
        stacktrace = Exception.format_stacktrace(System.stacktrace())

        """


        #{String.duplicate("!", 80)}

        #{message}
        #{Messages.get_help()}

        ---

        Here's the stacktrace for reference:

        #{stacktrace}
        """
        |> IOHelper.puts(:red)

        # case IOHelper.ask_yes_no("Permission to send this error to Timber?", api) do
        #   :yes ->
        #     data = %{message: message, stacktrace: stacktrace}
        #     API.event!(api, :exception, data: data)

        #   :no -> :ok
        # end

        :ok
    end
  end

  defp create_config_file!(application, api) do
    ConfigFile.create!(application, api)

    Messages.action_starting("Creating #{ConfigFile.file_path()}...")
    |> IOHelper.write()

    Messages.success()
    |> IOHelper.puts(:green)
  end

  defp link_config_file!(api) do
    file_explanation = "We need this to link config/timber.exs"
    config_file_path = PathHelper.find(["config", "config.exs"], file_explanation, api)

    if config_file_path do
      Messages.action_starting("Linking #{ConfigFile.file_path()} in #{config_file_path}...")
      |> IOHelper.write()

      ConfigFile.link!(config_file_path, api)

      Messages.success()
      |> IOHelper.puts(:green)
    end
  end

  defp add_plugs!(false, _), do: nil

  defp add_plugs!(true, api) do
    file_explanation = "We need this so that we can install the Timber plugs."
    endpoint_file_path = PathHelper.find(["{lib,web}", "**", "endpoint.ex"], file_explanation, api,
      check_for_umbrella: true)

    if endpoint_file_path do
      Messages.action_starting("Adding Timber plugs to #{endpoint_file_path}...")
      |> IOHelper.write()

      EndpointFile.update!(endpoint_file_path, api)

      Messages.success()
      |> IOHelper.puts(:green)
    end
  end

  defp disable_default_phoenix_logging!(false, _), do: nil

  defp disable_default_phoenix_logging!(true, api) do
    file_explanation = "We need this to disable default Phoenix controller logging."
    web_file_path = PathHelper.find(["web", "web.ex"], file_explanation, api,
      check_for_umbrella: true)

    if web_file_path do
      Messages.action_starting("Disabling default Phoenix logging #{web_file_path}...")
      |> IOHelper.write()

      WebFile.update!(web_file_path, api)

      Messages.success()
      |> IOHelper.puts(:green)
    end
  end

  defp install_user_context!(api) do
    """

    #{Messages.separator()}
    """
    |> IOHelper.puts()

    answer = IOHelper.ask_yes_no("Does your application have user accounts?", api)

    case answer do
      :yes ->
        Messages.user_context_instructions()
        |> IOHelper.puts()

        case IOHelper.ask_yes_no("Ready to proceed?", api) do
          :yes -> :ok
          :no -> install_user_context!(api)
        end

      :no ->
        false
    end
  end

  # defp install_http_client_context!(api) do
  #   """

  #   #{Messages.separator()}
  #   """
  #   |> IOHelper.puts()

  #    answer = IOHelper.ask_yes_no("Does your application send outgoing HTTP requests?", api)

  #   case answer do
  #     :yes ->
  #       Messages.outgoing_http_instructions()
  #       |> IOHelper.puts()

  #       case IOHelper.ask_yes_no("Ready to proceed?", api) do
  #         :yes -> :ok
  #         :no -> install_http_client_context!()
  #       end

  #     :no -> false
  #   end
  # end

  defp platform_install!(true, _api, _application) do
    """

    #{Messages.separator()}

    """
    |> IOHelper.write()

    Messages.action_starting("Checking if your application already has logs...")
    |> IOHelper.write()

    Messages.success()
    |> IOHelper.puts(:green)
  end

  defp platform_install!(false, api, %{platform_type: "heroku", heroku_drain_url: heroku_drain_url}) do
    Messages.heroku_drain_instructions(heroku_drain_url)
    |> IOHelper.puts()

    API.wait_for_logs(api)
  end

  defp platform_install!(false, %{api_key: api_key} = api, _application) do
    :ok = check_for_http_client(api)

    Messages.action_starting("Sending a few test logs...")
    |> IOHelper.write()

    # We manually initialize the backend here and mimic the behavior
    # of the GenEvent system

    {:ok, http_client} = Timber.LoggerBackends.HTTP.init(Timber.LoggerBackends.HTTP, [api_key: api_key])

    log_entries = TestThePipes.log_entries()

    http_client =
      Enum.reduce(log_entries, http_client, fn log_entry, http_client ->
        {:ok, http_client} = Timber.LoggerBackends.HTTP.handle_event(log_entry, http_client)
        http_client
      end)

    Timber.LoggerBackends.HTTP.handle_event(:flush, http_client)

    Messages.success()
    |> IOHelper.puts(:green)

    API.wait_for_logs(api)
  end

  defp check_for_http_client(api) do
    if Code.ensure_loaded?(:hackney) do
      API.event!(api, :http_client_found)

      case :hackney.start() do
        :ok -> :ok
        {:error, {:already_started, _name}} -> :ok
        other -> other
      end

      :ok
    else
      API.event!(api, :http_client_not_found)

      Messages.http_client_setup()
      |> IOHelper.puts(:red)

      exit :shutdown
    end
  end

  defp collect_feedback(api) do
    case IOHelper.ask("How would rate this install experience? 1 (bad) - 5 (perfect)", api) do
      v when v in ["4", "5"] ->
        API.event!(api, :feedback, %{rating: v})

        """

        💖  We love you too! Let's get to loggin' 🌲
        """
        |> IOHelper.puts()

      v when v in ["1", "2", "3"] ->
        """

        Bummer! That is certainly not the experience we were going for.

        Could you tell us why you a bad experience?

        (this will be sent directly to the Timber engineering team)
        """
        |> IOHelper.puts()

        case IOHelper.ask("Type your comments (enter sends)", api) do
          comments ->
            API.event!(api, :feedback, %{rating: v, comments: comments})

            """

            Thank you! We take feedback seriously and will work to resolve this.
            """
            |> IOHelper.puts()
        end

      v ->
        IOHelper.puts("#{inspect(v)} is not a valid option. Please enter a number between 1 and 5.\n", :red)
        collect_feedback(api)
    end
  end
end
