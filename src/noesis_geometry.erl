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
% @doc The `noesis_geometry' module provides functions (more or less) related to geometry.

-module(noesis_geometry).

-import(math, [
  asin/1,
  atan2/2,
  cos/1,
  log/1,
  pow/2,
  sin/1,
  sqrt/1,
  tan/1
]).

-import(noesis_math, [
  fmod/2
]).

-define(PI, math:pi()).
-define(PI_HALF, math:pi() / 2).
-define(PI_FOURTH, math:pi() / 4).
-define(R, 6372.8). % Earth radius

% Types

-type coordinates() :: {Longitude :: number(), Latitude :: number()}.

-export_type([
  coordinates/0
]).

% API
-export([
  lat/1,
  lng/1,
  distance/2,
  rhumb_destination_point/3,
  rhumb_bearing_to/2,
  deg2rad/1,
  rad2deg/1
]).

% API

% @doc Returns the latitude value of a `coordinates()' tuple.
-spec lat(coordinates()) -> number().
lat({_Lng, Lat}) -> Lat.

% @doc Returns the longitude value of a `coordinates()' tuple.
-spec lng(coordinates()) -> number().
lng({Lng, _Lat}) -> Lng.

% @doc Calculates the great-circle distance between two coordinates, that is the shortest distance between
%      two points on the surface of a sphere.<br />
%      `StartLng', `StartLat', `EndLng' and `EndLat' are all expected to be in degrees.
-spec distance(coordinates(), coordinates()) -> number().
distance({StartLng, StartLat}, {EndLng, EndLat}) ->
  DLng = deg2rad(EndLng - StartLng),
  DLat = deg2rad(EndLat - StartLat),
  RadStartLat = deg2rad(StartLat),
  RadEndLat = deg2rad(EndLat),
  A = pow(sin(DLat / 2), 2) + cos(RadStartLat) * cos(RadEndLat) * pow(sin(DLng / 2), 2),
  C = 2 * asin(sqrt(A)),
  ?R * C.

% @doc Given a starting point, a bearing and a distance, this will calculate the destination point.
%      If you maintain a constant bearing along a rhumb line, you will gradually spiral in towards one of the poles.<br />
%      `Point' and `Bearing' are both expected to be in degrees. `Distance' is expected to be in kilometers.<br /><br />
%      Based on <a href="http://www.movable-type.co.uk/scripts/latlong.html">Movable Type Scripts</a> by Chris Veness.
-spec rhumb_destination_point(coordinates(), number(), number()) -> coordinates().
rhumb_destination_point(Point, Bearing, Distance) ->
  D = Distance / ?R,
  {RadLng, RadLat} = deg2rad(Point),
  RadBrearing = deg2rad(Bearing),
  DestLat = RadLat + D * cos(RadBrearing),
  DLat = DestLat - RadLat,
  DPsi = log(tan(DestLat / 2 + ?PI_FOURTH) / tan(RadLat / 2 + ?PI_FOURTH)),
  Q = try (DLat / DPsi)
      catch
        error:_ -> cos(RadLat)
      end,
  DLng = D * sin(RadBrearing) / Q,
  DestLat2 = case abs(DestLat) > ?PI_HALF of
    true ->
      if
        DestLat > 0 -> ?PI - DestLat;
        true -> -(?PI - DestLat)
      end;
    false -> DestLat
  end,
  DestLng = fmod((RadLng + DLng + ?PI), (2 * ?PI)) - ?PI,
  {rad2deg(DestLng), rad2deg(DestLat2)}.

% @doc Given a starting point and a destination point, this will calculate the bearing between the two.<br />
%      `StartPoint' and `DestPoint' are both expected to be in degrees.<br /><br />
%      Partially based on <a href="http://www.movable-type.co.uk/scripts/latlong.html">Movable Type Scripts</a> by Chris Veness.
-spec rhumb_bearing_to(coordinates(), coordinates()) -> number().
rhumb_bearing_to(StartPoint, DestPoint) ->
  {RadStartLng, RadStartLat} = deg2rad(StartPoint),
  {RadDestLng, RadDestLat} = deg2rad(DestPoint),
  DLng = RadDestLng - RadStartLng,
  DPsi = log(tan(RadDestLat / 2 + ?PI_FOURTH) / tan(RadStartLat / 2 + ?PI_FOURTH)),
  DLng2 = case abs(DLng) > ?PI of
    true ->
      if
        DLng > 0 -> -(2 * ?PI - DLng);
        true -> (2 * ?PI + DLng)
      end;
    false -> DLng
  end,
  rad2deg(atan2(DLng2, DPsi)).

% @doc Converts degrees to radians.
-spec deg2rad(number() | coordinates()) -> number() | coordinates().
deg2rad({Lng, Lat}) -> {deg2rad(Lng), deg2rad(Lat)};
deg2rad(Deg) -> ?PI * Deg / 180.

% @doc Converts radians to degrees.
-spec rad2deg(number() | coordinates()) -> number() | coordinates().
rad2deg({Lng, Lat}) -> {rad2deg(Lng), rad2deg(Lat)};
rad2deg(Rad) -> 180 * Rad / ?PI.
