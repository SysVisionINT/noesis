% Copyright (c) 2014-2015, Daniel Kempkens <daniel@kempkens.io>
%
% Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted,
% provided that the above copyright notice and this permission notice appear in all copies.
%
% THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED
% WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL
% DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT,
% NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
%
% @author Daniel Kempkens <daniel@kempkens.io>
% @copyright {@years} Daniel Kempkens
% @version {@version}
% @doc The `noesis_math' module provides math related functions.

-module(noesis_math).

% API
-export([
  fmod/2,
  floor/1,
  ceiling/1
]).

% API

% @doc Returns the floating-point remainder of  `X' divided by `Y'.
-spec fmod(number(), number()) -> float().
fmod(X, Y) ->
  Div = float(trunc(X / Y)),
  X - Div * Y.

floor(X) when X < 0 ->
  T = trunc(X),
  if
    X - T == 0 -> T;
    true -> T - 1
  end;
floor(X) -> trunc(X).

ceiling(X) when X < 0 -> trunc(X);
ceiling(X) ->
  T = trunc(X),
  if
    X - T == 0 -> T;
    true -> T + 1
  end.
