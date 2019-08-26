-module(emqx_plugin_rabbitmq_app).

-behaviour(application).

-emqx_plugin(?MODULE).

-export([start/2
  , stop/1
]).

start(_StartType, _StartArgs) ->
  {ok, Sup} = emqx_plugin_rabbitmq_sup:start_link(),
  emqx_plugin_rabbitmq:load(application:get_all_env()),
  {ok, Sup}.

stop(_State) ->
  emqx_plugin_rabbitmq:unload().

