% Copyright (c) 2014, Daniel Kempkens <daniel@kempkens.io>
%
% Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted,
% provided that the above copyright notice and this permission notice appear in all copies.
%
% THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED
% WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL
% DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT,
% NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

-module(noesis_lists_test).

-include_lib("eunit/include/eunit.hrl").

group_by_test() ->
  ?assertEqual([{x, [1, 2, 3]}], noesis_lists:group_by(fun(_V) -> x end, [1, 2, 3])),
  ?assertEqual([{x, [{x, 1}, {x, 2}, {x, 3}]}], noesis_lists:group_by(fun({K, _V}) -> K end, [{x, 1}, {x, 2}, {x, 3}])),
  ?assertEqual([{x, [{x, 1}, {x, 3}]}, {y, [{y, 2}]}], noesis_lists:group_by(fun({K, _V}) -> K end, [{x, 1}, {y, 2}, {x, 3}])).

pmap_test() ->
  FunA = fun(X) -> X + 1 end,
  ListA = [1, 2, 10, 66, 99, 6, 3, 9000],
  ?assertEqual(lists:map(FunA, ListA), noesis_lists:pmap(FunA, ListA)),
  FunB = fun({_K, V}) -> V end,
  ListB = [{x, <<"hello">>}, {y, <<"test">>}, {z, <<"foo">>}],
  ?assertEqual(lists:map(FunB, ListB), noesis_lists:pmap(FunB, ListB)).
