defmodule Geobox do
  @moduledoc """
  Documentation for Geobox.
  """

  import Geohash, only: [encode: 3, decode_to_bits: 1, adjacent: 2]

  @radius_of_earth_kilometers 6_371.0088

  @doc ~S"""
  Return all the geohashes in radious with given precision
  ## Examples
  iex> Geobox.geohashes_within_radius({52.4267578125, 16.875}, 1, 6)
  ["u37fr9", "u37frc", "u3k421", "u3k423", "u37fr8", "u37frb", "u3k420", "u3k422", "u37fpx", "u37fpz", "u3k40p", "u3k40r", "u37fpw", "u37fpy", "u3k40n", "u3k40q"]

  iex> Geobox.geohashes_within_radius({52.4267578125, 16.875}, 5)
  ["u37fw", "u37fx", "u3k48", "u3k49", "u37fq", "u37fr", "u3k42", "u3k43", "u37fn", "u37fp", "u3k40", "u3k41", "u37cy", "u37cz", "u3k1b", "u3k1c"]
  """
  def geohashes_within_radius(point, km_radius, precision \\ 5) do
    point
    |> box_in_radius(km_radius)
    |> encode_geohashes(precision)
  end

  @doc ~S"""
  Return all the geohashes between min_y, min_x, max_y, max_x or polygon coordinates in resolution
  ## Examples
  iex> Geobox.encode_geohashes([16.9189453125, 52.470703125, 16.8310546875, 52.3828125])
  ["u37fr", "u3k42", "u37fp", "u3k40"]

  iex> Geobox.encode_geohashes([16.94874197310152, 52.47172383068623, 16.80125802689848, 52.38179179431377])
  ["u37fw", "u37fx", "u3k48", "u3k49", "u37fq", "u37fr", "u3k42", "u3k43", "u37fn", "u37fp", "u3k40", "u3k41", "u37cy", "u37cz", "u3k1b", "u3k1c"]

  iex> Geobox.encode_geohashes(%{coordinates: [{16.76513671875, 52.42587274336118}, {16.827621459960938, 52.33114320164082}, {16.967010498046875, 52.39403946901232}, {17.123565673828125, 52.391106301345005}, {16.941604614257813, 52.53376701989025}, {16.76513671875, 52.42587274336118}]}, 5)
  ["u3k4b", "u3k4c", "u3k4f", "u37fx", "u3k48", "u3k49", "u3k4d", "u3k4e", "u37fm", "u37fq", "u37fr", "u3k42", "u3k43", "u3k46", "u3k47", "u3k4k", "u37fj", "u37fn", "u37fp", "u3k40", "u3k41", "u3k44", "u3k45", "u3k4h", "u3k4j", "u37cy", "u37cz", "u3k1b", "u3k1c", "u37cw", "u37cx"]
  """
  def encode_geohashes(bb_or_coordinates, precision \\ 5) do
    [max_x, max_y, min_x, min_y] = corners(bb_or_coordinates)
    nw = encode(max_y, min_x, precision)
    sw = encode(min_y, min_x, precision)
    se = encode(min_y, max_x, precision)

    envelope_geohashes(bb_or_coordinates, nw, se, se, sw)
  end

  @doc ~S"""
  Decodes given geohash to a coordinates bounding box
  ## Examples
  iex> Geobox.decode_box("ezs42")
  [-5.5810546875, 42.626953125, -5.625, 42.5830078125]
  """
  def decode_box(geohash) do
    geohash
    |> decode_to_bits
    |> bits_to_box
  end

  # Geohash Helpers
  defp bits_to_box(bits) do
    bitslist = for << bit::1 <- bits >>, do: bit
    {min_y, max_y} = min_max_y(bitslist)
    {min_x, max_x} = min_max_x(bitslist)
    [max_x, max_y, min_x, min_y]
  end

  defp min_max_y(bitslist) do
    bitslist
    |> filter_odd
    |> Enum.reduce(fn (bit, acc) -> <<acc::bitstring, bit::bitstring>> end)
    |> bits_to_min_max({-90.0, 90.0})
  end

  defp min_max_x(bitslist) do
    bitslist
    |> filter_even
    |> Enum.reduce(fn (bit, acc) -> <<acc::bitstring, bit::bitstring>> end)
    |> bits_to_min_max({-180.0, 180.0})
  end

  defp filter_even(bitslists) do
    bitslists |> filter_periodically(2, 0)
  end

  defp filter_odd(bitslists) do
    bitslists |> filter_periodically(2, 1)
  end

  defp filter_periodically(bitslist, period, offset) do
    bitslist
    |> Enum.with_index
    |> Enum.filter(fn {_, i} -> rem(i, period) == offset end)
    |> Enum.map(fn {bit, _} -> <<bit::1>> end)
  end

  defp bits_to_min_max(<<>>, {min, max}), do: {min, max}
  defp bits_to_min_max(bits, {min, max}) do
    << bit::1, rest::bitstring >> = bits
    mid = (min + max) / 2
    {start, finish} = case bit do
      1 -> {mid, max}
      0 -> {min, mid}
    end
    bits_to_min_max(rest, {start, finish})
  end

  # Helpers
  defp envelope_geohashes(bb_or_coordinates, ne, base_se, se, sw, acc \\ []) do
    acc = if se |> decode_box() |> box_intersects?(bb_or_coordinates), do: [se | acc], else: acc

    if se == ne do
      acc
    else
      if sw == se do
        base_se = adjacent(base_se, "n")
        envelope_geohashes(bb_or_coordinates, ne, base_se, base_se, adjacent(sw, "n"), acc)
      else
        envelope_geohashes(bb_or_coordinates, ne, base_se, adjacent(se, "w"), sw, acc)
      end
    end
  end

  defp box_intersects?(bb, %{coordinates: coordinates}) do
    clip_polygon = bb |> box_to_envelope_coordinates()
    polygon_clipping(coordinates, clip_polygon) |> Enum.any?
  end
  defp box_intersects?([box1_max_x, box1_max_y, box1_min_x, box1_min_y], [box2_max_x, box2_max_y, box2_min_x, box2_min_y]) do
    cond do
      box1_min_x >= box2_max_x -> false
      box1_max_x <= box2_min_x -> false
      box1_min_y >= box2_max_y -> false
      box1_max_y <= box2_min_y -> false
      true -> true
    end
  end

  defp box_in_radius({lat, lon}, km_radius) do
    distance_rad = km_radius / @radius_of_earth_kilometers
    max_y = lat + rad_to_deg(distance_rad)
    min_y = lat - rad_to_deg(distance_rad)
    max_x = lon + rad_to_deg(distance_rad / :math.cos(deg_to_rad(lat)))
    min_x = lon - rad_to_deg(distance_rad / :math.cos(deg_to_rad(lat)))
    max_y = if max_y > 90, do: 90, else: max_y
    min_y = if max_y < -90, do: -90, else: min_y
    max_x = if max_x > 180, do: 180, else: max_x
    min_x = if min_x < -180, do: 180, else: min_x
    [max_x, max_y, min_x, min_y]
  end

  defp deg_to_rad(deg) do
    deg * (:math.pi / 180.0);
  end

  defp rad_to_deg(rad) do
    rad * (180.0 / :math.pi);
  end

  defp corners(bb) when is_list(bb), do: bb
  defp corners(%{coordinates: coordinates}) do
    coordinates
    |> List.flatten
    |> Enum.reduce([], fn({x, y}, acc) ->
      if acc == [] do
        [x, y, x, y]
      else
        [max_x, max_y, min_x, min_y] = acc
        [max(x, max_x), max(y, max_y), min(x, min_x), min(y, min_y)]
      end
    end)
  end

  defp box_to_envelope_coordinates([max_x, max_y, min_x, min_y]) do
    [{min_x, min_y}, {max_x, min_y}, {max_x, max_y}, {min_x, max_y}]
  end

  # Sutherland Hodgman
  defp polygon_clipping(subject_polygon, clip_polygon) do
    Enum.chunk([List.last(clip_polygon) | clip_polygon], 2, 1)
    |> Enum.reduce(subject_polygon, fn [cp1, cp2], acc ->
      Enum.chunk([List.last(acc) | acc], 2, 1)
      |> Enum.reduce([], fn [s, e], output_list ->
        case {inside(cp1, cp2, e), inside(cp1, cp2, s)} do
          {true,  true} -> [e | output_list]
          {true, false} -> [e, intersection(cp1, cp2, s, e) | output_list]
          {false, true} -> [intersection(cp1, cp2, s, e) | output_list]
          _             -> output_list
        end
      end)
      |> Enum.reverse
    end)
  end

  defp inside({cp1_x, cp1_y}, {cp2_x, cp2_y}, {x, y}), do: (cp2_x - cp1_x) * (y - cp1_y) > (cp2_y - cp1_y) * (x - cp1_x)

  defp intersection({cp1_x, cp1_y}, {cp2_x, cp2_y}, {sx, sy}, {ex, ey}) do
    {dcx, dcy} = {cp1_x - cp2_x, cp1_y - cp2_y}
    {dpx, dpy} = {sx - ex, sy - ey}
    n1 = cp1_x * cp2_y - cp1_y * cp2_x
    n2 = sx * ey - sy * ex
    n3 = 1.0 / (dcx * dpy - dcy * dpx)
    {(n1 * dpx - n2 * dcx) * n3, (n1 * dpy - n2 * dcy) * n3}
  end
end
