# Changelog

## v0.2.0

### Enhancements

* Consumer knows its routing_key, call: `MyConsumer.routing_key/0`
* updated amqp which results in chatty logs, use following config to mute it

  ```elixir
  # disable amqp hex package logs
  config :lager,
    error_logger_redirect: false,
    handlers: [level: :critical]
  ```

### Breaking Changes

* Consumer process stops if connection is lost
* `use Tackle.Consumer` option `url` is renamed to `rabbitmq_url`
* `Tackle.publish` option `url` is renamed to `rabbitmq_url`
* `use Tackle.Consumer` option `exchange` is renamed to `remote_exchange`
