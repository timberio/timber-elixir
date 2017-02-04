# :evergreen_tree: Timber - Master your Elixir apps with structured logging

<p align="center" style="background: #140f2a;">
<a href="http://github.com/timberio/timber-elixir"><img src="http://files.timber.io/images/ruby-library-readme-header.gif" height="469" /></a>
</p>

[![ISC License](https://img.shields.io/badge/license-ISC-ff69b4.svg)](LICENSE.md) [![Hex.pm](https://img.shields.io/hexpm/v/timber.svg?maxAge=18000=plastic)](https://hex.pm/packages/timber) [![Documentation](https://img.shields.io/badge/hexdocs-latest-blue.svg)](https://hexdocs.pm/timber/index.html) [![CircleCI branch](https://img.shields.io/circleci/project/timberio/timber-elixir/master.svg?maxAge=18000=plastic)](https://circleci.com/gh/timberio/timber-elixir/tree/master) [![Coverage Status](https://coveralls.io/repos/github/timberio/timber-elixir/badge.svg?branch=master)](https://coveralls.io/github/timberio/timber-elixir=master)

**Note: Timber is in beta testing, if interested in joining, please visit https://timber.io**

Logs are amazingly useful...when they're structured. And unless you're a logging company,
designing, implementing, and maintaining a structured logging strategy can be a major time sink.

Timber gives you this *today*. It's a fully-managed structured logging system that...

1. Automatically structures your framework and 3rd party logs ([see below](#what-events-does-timber-structure-for-me)).
2. Provides a [framework for logging custom events](#what-about-custom-events).
3. Defines a [normalized shared log schema](https://github.com/timberio/log-event-json-schema) across *all* of your apps.
4. Offers a [beautiful modern console](https://timber.io) designed specifically for this data. Pre-configured and tuned out of the box.
5. Gives you *6 months of retention*, by default.
6. Does not charge you for the extra structured data we're encouraging here, only the core log message.
7. Encrypts your data in transit and at rest.
8. Offers 11 9s of durability.
9. ...and so much more!

To learn more, checkout out [timber.io](https://timber.io) or the
["why we started Timber"](http://moss-ibex2.cloudvent.net/blog/why-were-building-timber/)
blog post.


## What events does Timber structure for me?

Out of the box you get everything in the [`Timber.Events`](lib/timber/events) namespace:

1. [Controller Call Event](lib/timber/events/controller_call_event.ex)
2. [Exception Event](lib/timber/events/exception_event.ex)
3. [HTTP Client Request Event (outgoing)](lib/timber/events/http_client_request_event.ex)
4. [HTTP Client Response Event](lib/timber/events/http_client_response_event.ex)
5. [HTTP Server Request Event (incoming)](lib/timber/events/http_server_request_event.ex)
6. [HTTP Server Response Event](lib/timber/events/http_server_response_event.ex)
7. [SQL Query Event](lib/timber/events/sql_query_event.ex)
8. [Template Render Event](lib/timber/events/template_render_event.ex)
9. ...more coming soon, [file an issue](https://github.com/timberio/timber-elixir/issues) to request.

We also add context to every log, everything in the [`Timber.Contexts`](lib/timber/contexts)
namespace. Context is like join data for your logs. Ever wish you could see all log lines written
a specific request? Context achieves that:

1. [HTTP Context](lib/timber/contexts/http_context.ex)
2. [Organization Context](lib/timber/contexts/organization_context.ex)
3. [Process Context](lib/timber/contexts/process_context.ex)
4. [Server Context](lib/timber/contexts/server_context.ex)
5. [Runtime Context](lib/timber/contexts/runtime_context.ex)
6. ...more coming soon, [file an issue](https://github.com/timberio/timber-elixir/issues) to request.


## What about custom events?

No probs! We've put careful thought in how this would be implemented. You have a couple of options
depending on how strict you want to be with structuring your events.

1. Log a map (simplest)

  ```elixir
  event_data = %{customer_id: "xiaus1934", amount: 1900, currency: "USD"}
  Logger.info("Payment rejected", event: %{type: :payment_rejected, data: event_data})
  ```

2. Log a struct (recommended)

  Defining structs for your important events just feels oh so good :) It creates a strong contract
  with down stream consumers and gives you compile time guarantees.

  ```elixir
  def PaymentRejectedEvent do
    use Timber.Events.CustomEvent, type: :payment_rejected

    @enforce_keys [:customer_id, :amount, :currency]
    defstruct [:customer_id, :amount, :currency]

    def message(%__MODULE__{customer_id: customer_id}) do
      "Payment rejected for #{customer_id}"
    end
  end

  event = %PaymentRejectedEvent{customer_id: "xiaus1934", amount: 1900, currency: "USD"}
  message = PaymentRejectedEvent.message(event)
  Logger.info(message, event: event)
  ```

Notice there are no special APIs, no risk of code-debt, and no lock-in. Just better logging.


## Installation

1. Add Timber as a dependency in `Mix.exs`:

  ```elixir
  # Mix.exs

  def application do
    [applications: [:timber]]
  end

  def deps do
    [{:timber, "~> 1.0"}]
  end
  ```

2. Configure Timber in `config/config.exs`:

  ```elixir
  # config/config.exs

  config :logger,
    backends: [Timber.LoggerBackend],
    handle_otp_reports: false # Timber handles this and adds additional metadata

  config :timber, :capture_errors, true
  ```

3. Install the Timber plugs:

  1. Remove the existing `Plug.Logger` in `lib/my_app/endpoint.ex`:

    ```elixir
    # lib/my_app/endpoint.ex

    plug Plug.Logger # <--- REMOVE ME
    ```

  2. Add the Timber plugs in `web/router.ex`:

    ```elixir
    # web/router.ex

    defmodule MyApp.Router do
      use MyApp.Web, :router

      pipeline :logging do
        plug Timber.Integrations.ContextPlug
        plug Timber.Integrations.EventPlug
      end

      scope "/api", MyApp do
        pipe_through :logging
      end
    end
    ```

    * To learn more about what each of these plugs are doing, checkout the docs:
      [Timber.Integrations.ContextPlug](lib/timber/integrations/context_plug.ex) and
      [Timber.Integrations.EventPlug](lib/timber/integrations/event_plug.ex)

4. Add Phoenix instrumentation in `config/config.exs`:

  Skip if you are not using `Phoenix`.

  ```elixir
  # config/config.exs

  config :my_app, MyApp.Endpoint,
    http: [port: 4001],
    root: Path.dirname(__DIR__),
    instrumenters: [Timber.Integrations.PhoenixInstrumenter], # <------ add this line
    pubsub: [name: MyApp.PubSub,
             adapter: Pheonix.PubSub.PG2]
  ```

5. Add the Ecto logger in `config/config.exs`:

  Skip if you are not using `Ecto`.

  ```elixir
  # config/config.exs

  config :my_app, MyApp.Repo,
    loggers: [{Timber.Integrations.EctoLogger, :log, [:info]}] # Bumped to info to gain more insight
  ```

6. Whew! Done! You've now got a fully managed structured logging solution.

## Send your logs



<details><summary><h3>Heroku instructions</h3></summary><p>

```
These are instructions
```
</p></details>






The last step is getting your logs to the Timber service. We *highly* recmmend that you
[create an app within your Timber account](https://app.timber.io/organizations/timber/apps/new)
and follow the instructions that proceed. Based on your app details we'll provide you with simple,
straight-forward instructions that get you up and running quickly.

### STDOUT

Do nothing! This is the default transport strategy.

### File

1. Configure the Timber transport strategy:

  ```elixir
  config :timber, :transport, Timber.Transports.IODevice
  config :timber, :io_device,
    file: "path/to/file",
  ```

* Note, this requires our agent to send the file contents to Timber.

### HTTP

Coming soon!


## Development environment?

Bonus points! Use Timber in your development environment so you can see context locally:

```elixir
# config/dev.exs

config :timber, :io_device,
  colorize: true,
  format: :logfmt,
  print_timestamps: true
  print_log_level: true
```

---

<p align="center" style="background: #140f2a;">
<a href="http://github.com/timberio/timber-elixir"><img src="http://files.timber.io/images/ruby-library-readme-log-truth.png" height="947" /></a>
</p>