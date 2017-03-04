# 🌲 Timber - Master your Elixir apps with structured logging

<p align="center" style="background: #140f2a;">
<a href="http://files.timber.io/images/readme-interface.gif"><img src="http://files.timber.io/images/readme-interface.gif" width="100%" /></a>
</p>

[![ISC License](https://img.shields.io/badge/license-ISC-ff69b4.svg)](LICENSE.md) [![Hex.pm](https://img.shields.io/hexpm/v/timber.svg?maxAge=18000=plastic)](https://hex.pm/packages/timber) [![Documentation](https://img.shields.io/badge/hexdocs-latest-blue.svg)](https://hexdocs.pm/timber/index.html) [![CircleCI branch](https://img.shields.io/circleci/project/timberio/timber-elixir/master.svg?maxAge=18000=plastic)](https://circleci.com/gh/timberio/timber-elixir/tree/master)


Still logging raw text? Timber is a *structured* logging system that you can setup in
minutes. It solves logging so you don't have to!

To learn more, checkout out [timber.io](https://timber.io).


## Installation

1. Add `timber` as a dependency in `mix.exs`:

    ```elixir
    # Mix.exs

    def application do
      [applications: [:timber]]
    end

    def deps do
      [{:timber, "~> 1.0"}]
    end
    ```

2. Run `mix deps.get` in your shell.

3. Run `mix timber.install your-timber-application-api-key`


## Usage

<details><summary><strong>Basic logging</strong></summary><p>

No client, no special API, no magic, just use `Logger` as normal:

```elixir
Logger.info("My log message")

# My log message @metadata {"level": "info", "context": {...}}
```

---

</p></details>

<details><summary><strong>Tagging logs</strong></summary><p>

Tags provide a quick way to identify logs. They work just like any tagging system.
In the context of logging, they prevent obstructing the log message to
accomplish the same thing, while also being a step down from creating a classified custom
event. If the event is meaningful in any way, we recommend creating a custom event.

```elixir
Logger.info("My log message", tags: ["tag"])

# My log message @metadata {"level": "info", "tags": ["tag"], "context": {...}}
```

* In the Timber console use the query: `tags:tag`.

---

</p></details>

<details><summary><strong>Timings</strong></summary><p>

Timings allow you to easily capture one-off timings in your code; a simple
way to benchmark code execution:


```elixir
timer = Timber.start_timer()
# ... code to time ...
time_ms = Timber.duration_ms(timer)
Logger.info("Task complete", tags: ["my_task"] time_ms: time_ms)

# Task complete @metadata {"level": "info", "tags": ["my_task"], "time_ms": 56.4324, "context": {...}}
```

* In the Timber console use the query: `tags:my_task time_ms>500`
* The Timber console will also display this value inline with your logs. No need to include it
  in the log message, but you certainly can if you'd prefer.

---

</p></details>

<details><summary><strong>Custom events</strong></summary><p>

Custom events can be used to structure information about events that are central
to your line of business like receiving credit card payments, saving a draft of a post,
or changing a user's password. You have 2 options to do this:

1. Log a map (simplest)

  The simplest way to send an event and kick the tires:

  ```elixir
  event_data = %{customer_id: "xiaus1934", amount: 1900, currency: "USD"}
  Logger.info("Payment rejected", event: %{payment_rejected: event_data})

  # Payment rejected @metadata {"level": "warn", "event": {"payment_rejected": {"customer_id": "xiaus1934", "amount": 100, "reason": "Card expired"}}, "context": {...}}
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

  # Payment rejected @metadata {"level": "warn", "event": {"payment_rejected": {"customer_id": "xiaus1934", "amount": 100, "reason": "Card expired"}}, "context": {...}}
  ```

* In the Timber console use queries like: `payment_rejected.customer_id:xiaus1934` or `payment_rejected.amount>100`
* Also, notice there is no mention of Timber in the above code. Just plain old logging.

#### What about regular Hashes, JSON, or logfmt?

Go for it! Timber will parse the data server side, but we *highly* recommend the above examples.
Providing a `:type` allows timber to classify the event, create a namespace for the data you
send, and make it easier to search, graph, alert, etc.

```ruby
Logger.info(%{key: "value"})
# {"key": "value"} @metadata {"level": "info", "context": {...}}

Logger.info('{"key": "value"}')
# {"key": "value"} @metadata {"level": "info", "context": {...}}

Logger.info("key=value")
# key=value @metadata {"level": "info", "context": {...}}
```

---

</p></details>

<details><summary><strong>Custom contexts</strong></summary><p>

Context is additional data shared across log lines. Think of it like join data. For example, the
`http.request_id` is included in the context, allowing you to view all log lines related to that
request ID. Not just the lines that contain the value.

1. Add a map (simplest)

  The simplest way to add context is:

  ```elixir
  Timber.add_context(%{build: %{version: "1.0.0"}})
  Logger.info("My log message")

  # My log message @metadata {"level": "info", "context": {"build": {"version": "1.0.0"}}}
  ```

  This adds context data keyspaces by `build`.

2. Add a struct (recommended)

  Just like events, we recommend defining your custom contexts. It makes a stronger contract
  with downstream consumers.

  ```elixir
  def BuildContext do
    use Timber.Contexts.CustomContext, type: :build
    @enforce_keys [:version]
    defstruct [:version]
  end

  Timber.add_context(%BuildContext{version: "1.0.0"})
  Loger.info("My log message")

  # My log message @metadata {"level": "info", "context": {"build": {"version": "1.0.0"}}}
  ```

* In the Timber console use a query like: `context.build.version:1.0.0`

</p></details>


## Jibber-Jabber

<details><summary><strong>What specifically does the Timber library do?</strong></summary><p>

1. Captures and structures your framework and 3rd party logs. (see next question)
2. Adds useful context to every log line. (see next question)
3. Allows you to easily add tags and timings to your logs. (see [Usage](#usage))
4. Provides a framework for logging custom events. (see [Usage](#usage))
5. Provides a framework for adding custom context shared across your logs. (see [Usage](#usage))
6. Offers transport strategies to [send your logs](#send-your-logs) to the Timber service.

---

</p></details>

<details><summary><strong>Which log events does Timber structure for me?</strong></summary><p>

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
namespace. Context is structured data representing the current environment when the log line was written.
It is included in every log line. Think of it like join data for your logs:

1. [HTTP Context](lib/timber/contexts/http_context.ex)
2. [Organization Context](lib/timber/contexts/organization_context.ex)
3. [Server Context](lib/timber/contexts/server_context.ex)
4. [System Context](lib/timber/contexts/system_context.ex)
5. [Runtime Context](lib/timber/contexts/runtime_context.ex)
5. [User Context](lib/timber/contexts/user_context.ex)
6. ...more coming soon, [file an issue](https://github.com/timberio/timber-elixir/issues) to request.

---

</p></details>

<details><summary><strong>What about my current log statements?</strong></summary><p>

They'll continue to work as expected. Timber adheres strictly to the default `Logger` interface
and will never deviate in *any* way.

In fact, traditional log statements for non-meaningful events, debug statements, etc, are
encouraged. In cases where the data is meaningful, consider [logging a custom event](#usage).

</p></details>

<details><summary><strong>How is Timber different?</strong></summary><p>

1. **No lock-in**. Timber is just _better_ logging. There is no special API and no risk of vendor
   lock-in.
2. **Data quality.** Instead of relying on parsing alone, Timber ships libraries that structure
   and augment your logs from _within_ your application. Improving your log data at the source.
3. **Human readability.** Structuring your logs doesn't have to mean losing readability. Instead,
   Timber _augments_ them. For example: `log message @metadata {...}`. And when you view them in the
   [Timber console](https://app.timber.io), you'll see human friendly messages with the ability
   to view the attached metadata.
4. **Sane prices, long retention**. Logging is notoriously expensive with low retention. Timber
   is affordable and offers 6 months of retention by default.
5. **Normalized schema.** Have multiple apps? All of Timber's libraries adhere to our
   [JSON schema](https://github.com/timberio/log-event-json-schema). This means queries, alerts,
   and graphs for your ruby app can also be applied to your elixir app (for example).

---

</p></details>

---

<p align="center" style="background: #221f40;">
<a href="http://github.com/timberio/timber-elixir"><img src="http://files.timber.io/images/ruby-library-readme-log-truth.png" height="947" /></a>
</p>
