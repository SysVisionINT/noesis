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
%
% Modifications copyright (C) 2018 SysVision, Lda.
%

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

-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").
-endif.

-define(PI, 3.141592653589793). % math:pi()
-define(PI_HALF, 1.5707963267948966). % math:pi() / 2
-define(PI_FOURTH, 0.7853981633974483). % math:pi() / 4
-define(R, 6372.8). % Earth radius

% Types

-type latitude() :: number().
-type longitude() :: number().
-type bearing() :: number().
-type coordinates() :: {Latitude :: latitude(), Longitude :: longitude()}.
-type path() :: [coordinates()].
-type bounds() :: {NorthEast :: coordinates(), SouthWest :: coordinates()}.

-export_type([
	latitude/0,
	longitude/0,
	bearing/0,
	coordinates/0,
	path/0,
	bounds/0
]).

% API
-export([
	lat/1,
	lng/1,
	north_east/1,
	south_west/1,
	center/1,
	contains_point/2,
	extend/2,
	crosses_antimeridian/1,
	distance/2,
	rhumb_distance/2,
	rhumb_destination_point/3,
	rhumb_bearing_to/2,
	deg2rad/1,
	rad2deg/1,
	normalize_lat/1,
	normalize_lng/1,
	normalize_bearing/1
]).

% API

% @doc Returns the latitude value of a {@link coordinates()} tuple.
-spec lat(Coordinates :: coordinates()) -> latitude().
lat({Lat, _Lng}) -> Lat.

% @doc Returns the longitude value of a {@link coordinates()} tuple.
-spec lng(Coordinates :: coordinates()) -> longitude().
lng({_Lat, Lng}) -> Lng.

% @doc Returns the NE value of a {@link bounds()} tuple.
-spec north_east(Bounds :: bounds()) -> coordinates().
north_east({NE, _SW}) -> NE.

% @doc Returns the SW value of a {@link bounds()} tuple.
-spec south_west(Bounds :: bounds()) -> coordinates().
south_west({_NE, SW}) -> SW.

% @doc Calculates the center point of a {@link bounds()} tuple.
-spec center(bounds()) -> coordinates().
center({{NELat, NELng}, {SWLat, SWLng}}=Bounds) ->
	Lng = case crosses_antimeridian(Bounds) of
		true ->
			Span = lng_span(SWLng, NELng),
			normalize_lng(SWLng + Span / 2);
		false -> (SWLng + NELng) / 2
	end,
	Lat = (SWLat + NELat) / 2,
	{Lat, Lng}.

% @doc Checks whether or not a given point is inside the supplied {@link bounds()} tuple.
-spec contains_point(bounds(), coordinates()) -> boolean().
contains_point({{NELat, _NELng}, {SWLat, _SWLng}}, {Lat, _Lng}) when SWLat > Lat orelse Lat > NELat ->
	false;
contains_point(Bounds, Point) ->
	contains_lng(Bounds, Point).

% @doc Extends the {@link bounds()} tuple by the given point, if the bounds don't already contain the point.
-spec extend(bounds(), coordinates()) -> bounds().
extend({{NELat, NELng}, {SWLat, SWLng}}=Bounds, {Lat, Lng}=Point) ->
	NELat2 = max(NELat, Lat),
	SWLat2 = min(SWLat, Lat),
	case contains_lng(Bounds, Point) of
		true -> {{NELat2, NELng}, {SWLat2, SWLng}};
		false ->
			case lng_span(SWLng, Lng) =< lng_span(Lng, NELng) of
				true -> {{NELat2, Lng}, {SWLat2, SWLng}};
				false -> {{NELat2, NELng}, {SWLat2, Lng}}
			end
	end.

% @doc Returns whether or not the bounds intersect the antimeridian.
-spec crosses_antimeridian(Bounds :: bounds()) -> boolean().
crosses_antimeridian({{_NELat, NELng}, {_SWLat, SWLng}}) ->
	SWLng > NELng.

% @doc Calculates the great-circle distance between two coordinates, that is the shortest distance between
%      two points on the surface of a sphere.<br />
%      `StartLng', `StartLat', `EndLng' and `EndLat' are all expected to be in degrees.
-spec distance(StartCoordinates :: coordinates(), DestCoordinates :: coordinates()) -> number().
distance({StartLat, StartLng}, {DestLat, DestLng}) ->
	DLng = deg2rad(DestLng - StartLng),
	DLat = deg2rad(DestLat - StartLat),
	RadStartLat = deg2rad(StartLat),
	RadDestLat = deg2rad(DestLat),
	A = pow(sin(DLat / 2), 2) + cos(RadStartLat) * cos(RadDestLat) * pow(sin(DLng / 2), 2),
	C = 2 * asin(sqrt(A)),
	?R * C.

% @doc Given a starting point and a destination point, this will calculate the distance between the two.<br />
%      `StartPoint' and `DestPoint' are both expected to be in degrees.<br /><br />
%      Partially based on <a href="http://www.movable-type.co.uk/scripts/latlong.html">Movable Type Scripts</a> by Chris Veness.
-spec rhumb_distance(StartCoordinates :: coordinates(), DestCoordinates :: coordinates()) -> number().
rhumb_distance({StartLat, StartLng}, {DestLat, DestLng}) ->
	DLng = deg2rad(abs(DestLng - StartLng)),
	DLat = deg2rad(DestLat - StartLat),
	RadStartLat = deg2rad(StartLat),
	RadDestLat = deg2rad(DestLat),
	Q = rhumb_calculate_q(DLat, RadStartLat, RadDestLat),
	DLng2 = rhumb_bounds_check(abs(DLng) > ?PI, -(2 * ?PI - DLng), 2 * ?PI + DLng, DLng),
	Delta = sqrt(DLat * DLat + Q * Q * DLng2 * DLng2),
	?R * Delta.

% @doc Given a starting point, a bearing and a distance, this will calculate the destination point.
%      If you maintain a constant bearing along a rhumb line, you will gradually spiral in towards one of the poles.<br />
%      `Point' and `Bearing' are both expected to be in degrees. `Distance' is expected to be in kilometers.<br /><br />
%      Based on <a href="http://www.movable-type.co.uk/scripts/latlong.html">Movable Type Scripts</a> by Chris Veness.
-spec rhumb_destination_point(coordinates(), bearing(), number()) -> coordinates().
rhumb_destination_point(Point, Bearing, Distance) ->
	D = Distance / ?R,
	{RadLat, LLng} = deg2rad(Point),
	RadBearing = deg2rad(Bearing),
	DPhi = D * cos(RadBearing),
	RadLat2 = RadLat + DPhi,
	RadLat3 = rhumb_bounds_check(abs(RadLat2) > ?PI_HALF, ?PI - RadLat2, -?PI - RadLat2, RadLat2),
	Q = rhumb_calculate_q(DPhi, RadLat, RadLat3),
	DL = D * sin(RadBearing) / Q,
	LLng2 = fmod(LLng + DL + 3 * ?PI, 2 * ?PI) - ?PI,
	{rad2deg(RadLat3), rad2deg(LLng2)}.

% @doc Given a starting point and a destination point, this will calculate the bearing between the two.<br />
%      `StartPoint' and `DestPoint' are both expected to be in degrees.<br /><br />
%      Partially based on <a href="http://www.movable-type.co.uk/scripts/latlong.html">Movable Type Scripts</a> by Chris Veness.
-spec rhumb_bearing_to(coordinates(), coordinates()) -> float().
rhumb_bearing_to(StartPoint, DestPoint) ->
	{RadStartLat, RadStartLng} = deg2rad(StartPoint),
	{RadDestLat, RadDestLng} = deg2rad(DestPoint),
	DLng = RadDestLng - RadStartLng,
	DLng2 = rhumb_bounds_check(abs(DLng) > ?PI, -(2 * ?PI - DLng), 2 * ?PI + DLng, DLng),
	Bearing = if
		abs(RadStartLat) == ?PI_HALF orelse abs(RadDestLat) == ?PI_HALF -> 0;
		true ->
			DPsi = log(tan(RadDestLat / 2 + ?PI_FOURTH) / tan(RadStartLat / 2 + ?PI_FOURTH)),
			rad2deg(atan2(DLng2, DPsi))
	end,
normalize_bearing(Bearing).

% @doc Converts degrees to radians.
-spec deg2rad(number() | coordinates()) -> number() | coordinates().
deg2rad({Lat, Lng}) ->
	{deg2rad(Lat), deg2rad(Lng)};
deg2rad(Deg) ->
	?PI * Deg / 180.

% @doc Converts radians to degrees.
-spec rad2deg(number() | coordinates()) -> number() | coordinates().
rad2deg({Lat, Lng}) ->
	{rad2deg(Lat), rad2deg(Lng)};
rad2deg(Rad) ->
	180 * Rad / ?PI.

% @doc Normalizes a latitude to the `[-90, 90]' range. Latitudes above 90 or below -90 are capped, not wrapped.
-spec normalize_lat(latitude()) -> latitude().
normalize_lat(Lat) ->
	float(max(-90, min(90, Lat))).

% @doc Normalizes a longitude to the `[-180, 180]' range. Longitudes above 180 or below -180 are wrapped.
-spec normalize_lng(longitude()) -> longitude().
normalize_lng(Lng) ->
	Lng2 = fmod(Lng, 360),
	normalize_lng_bounds(Lng2).

% @doc Normalizes a bearing to the `[0, 360]' range. Bearings above 360 or below 0 are wrapped.
-spec normalize_bearing(bearing()) -> bearing().
normalize_bearing(Bearing) ->
	fmod((fmod(Bearing, 360) + 360), 360).

% Private

-spec lng_span(longitude(), longitude()) -> number().
lng_span(West, East) when West > East ->
	East + 360 - West;
lng_span(West, East) ->
	East - West.

-spec contains_lng(bounds(), coordinates()) -> boolean().
contains_lng({{_NELat, NELng}, {_SWLat, SWLng}}=Bounds, {_Lat, Lng}) ->
	case crosses_antimeridian(Bounds) of
		true -> (Lng =< NELng) or (Lng >= SWLng);
		false -> (SWLng =< Lng) and (Lng =< NELng)
	end.

-spec normalize_lng_bounds(longitude()) -> float().
normalize_lng_bounds(Lng) when Lng == 180 ->
	180.0;
normalize_lng_bounds(Lng) when Lng < -180 ->
	Lng + 360.0;
normalize_lng_bounds(Lng) when Lng > 180 ->
	Lng - 360.0;
normalize_lng_bounds(Lng) ->
	float(Lng).

-spec rhumb_bounds_check(boolean(), number(), number(), number()) -> number().
rhumb_bounds_check(true, GtZero, _LteZero, Default) when Default > 0 ->
	GtZero;
rhumb_bounds_check(true, _GtZero, LteZero, _Default) ->
	LteZero;
rhumb_bounds_check(false, _GtZero, _LteZero, Default) ->
	Default.

-spec rhumb_calculate_q(number(), number(), number()) -> number().
rhumb_calculate_q(_DLat, RadStartLat, RadDestLat) when abs(RadStartLat) == ?PI_HALF orelse
	abs(RadDestLat)  == ?PI_HALF ->
	cos(RadStartLat);
rhumb_calculate_q(DLat, RadStartLat, RadDestLat) ->
	DPsi = log(tan(RadDestLat / 2 + ?PI_FOURTH) / tan(RadStartLat / 2 + ?PI_FOURTH)),
	try (DLat / DPsi)
	catch
		error:_ -> cos(RadStartLat)
	end.

% Tests (private functions)

-ifdef(TEST).
lng_span_test() ->
	?assertEqual(350, lng_span(20, 10)),
	?assertEqual(0, lng_span(10, 10)).

rhumb_bounds_check_test() ->
	?assertEqual(9001, rhumb_bounds_check(true, 9001, 0, 1)),
	?assertEqual(9001, rhumb_bounds_check(true, 0, 9001, 0)),
	?assertEqual(9001, rhumb_bounds_check(false, 0, 0, 9001)).
-endif.
