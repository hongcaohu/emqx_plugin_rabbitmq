-module(emqx_plugin_rabbitmq_cli).

-behaviour(ecpool_worker).

-include("../include/emqx_plugin_rabbitmq.hrl").
-include("../../amqp_client/include/amqp_client.hrl").
-export([connect/1]).
-export([ensure_exchange/1, publish/3]).

connect(Opts) ->
  io:format("hook_rabbitmq_host: ~s~n", [proplists:get_value(host, Opts)]),
  ConnOpts = #amqp_params_network{
    host = proplists:get_value(host, Opts),
    port = proplists:get_value(port, Opts),
    username = proplists:get_value(username, Opts),
    password = proplists:get_value(password, Opts)
  },
  {ok, C} = amqp_connection:start(ConnOpts),
  {ok, C}.

ensure_exchange(ExchangeName) ->
  io:format("cli ExchangeName: ~s~n", [ExchangeName]),
  ecpool:with_client(?APP, fun(C) -> ensure_exchange(ExchangeName, C) end).

ensure_exchange(ExchangeName, Conn) ->
    io:format("cli ExchangeName 2: ~s~n", [ExchangeName]),
  {ok, Channel} = amqp_connection:open_channel(Conn),
  Declare = #'exchange.declare'{exchange = ExchangeName, durable = true},
  #'exchange.declare_ok'{} = amqp_channel:call(Channel, Declare),
  amqp_channel:close(Channel).

publish(ExchangeName, Payload, RoutingKey) ->
  ecpool:with_client(rabbitmq_pool, fun(C) -> publish(ExchangeName, Payload, RoutingKey, C) end).

publish(ExchangeName, Payload, RoutingKey, Conn) ->
  io:format("public method invoked ..."),
  {ok, Channel} = amqp_connection:open_channel(Conn),
  Publish = #'basic.publish'{exchange = <<"amq.topic">>, routing_key = RoutingKey},
  Props = #'P_basic'{delivery_mode = 2},
  Msg = #amqp_msg{props = Props, payload = Payload},

  io:format("before cast ..... ~n"),
  io:format("Channel : ~p ~n", [Channel]),
  amqp_channel:cast(Channel, Publish, Msg).
  amqp_channel:close(Channel).


