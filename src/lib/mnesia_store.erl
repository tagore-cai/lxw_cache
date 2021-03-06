-module (mnesia_store).

-export([init/0, insert/2, delete/1, lookup/1,delete_cache/1]).

-define(TABLE_ID, ?MODULE).
-record(key_to_value, {key, value, time}).

init() ->
    mnesia:start(),
    mnesia:create_table(key_to_value,
                        [{index, [key]},
                            {attributes, record_info(fields, key_to_value)}]).

insert(Key, Value) ->
    Current_time = time_utils:get_current_seconds(),
    mnesia:dirty_write(#key_to_value{key = Key, value = Value, time = Current_time}).

lookup(Key) ->
    case mnesia:dirty_read(key_to_value, Key) of
        [{key_to_value, Key, Value, Time}] ->
            {ok, Value, Time};
        [] ->
            {error, not_found}
    end.

delete(Key) ->
    case mnesia:dirty_index_read(key_to_value, Key, #key_to_value.key) of
        [#key_to_value{} = Record] ->
            mnesia:dirty_delete_object(Record);
        _ ->
            ok
    end.
delete_cache(OutTime)->
    TimeTemp = time_utils:get_current_seconds() - OutTime,
    MatchHead= #key_to_value{key = '$1', _ = '_', time = '$2'},
    Guard={'<', '$2', TimeTemp},
    Result='$1',
    Keys=mnesia:select(?TABLE_ID,[{MatchHead, [Guard], [Result]}]),
    lists:foldl(fun(_, key) -> mnesia:delete(key) end, 0,Keys).