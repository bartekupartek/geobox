defmodule GeoboxTest do
  use ExUnit.Case
  doctest Geobox

  test "encode geohashes in radious" do
    geohashes = ["u37fr9", "u37frc", "u3k421", "u3k423", "u37fr8", "u37frb", "u3k420", "u3k422", "u37fpx", "u37fpz", "u3k40p", "u3k40r", "u37fpw", "u37fpy", "u3k40n", "u3k40q"]
    assert geohashes == Geobox.geohashes_within_radius({52.4267578125, 16.875}, 1, 6)
    geohashes = ["u37fw", "u37fx", "u3k48", "u3k49", "u37fq", "u37fr", "u3k42", "u3k43", "u37fn", "u37fp", "u3k40", "u3k41", "u37cy", "u37cz", "u3k1b", "u3k1c"]
    assert geohashes == Geobox.geohashes_within_radius({52.4267578125, 16.875}, 5)
    assert ["u37f", "u3k4", "u37c", "u3k1"] == Geobox.geohashes_within_radius({52.4267578125, 16.875}, 10, 4)
  end

  test "encode envelope geohashes" do
    bounds = [16.9189453125, 52.470703125, 16.8310546875, 52.3828125]
    geohashes = ["u37fr", "u3k42", "u37fp", "u3k40"]
    assert geohashes == Geobox.encode_geohashes(bounds, 5)
    bounds = [16.91, 52.47, 16.83, 52.38]
    geohashes = ["u37fq", "u37fr", "u3k42", "u37fn", "u37fp", "u3k40", "u37cy", "u37cz", "u3k1b"]
    assert geohashes == Geobox.encode_geohashes(bounds, 5)
  end

  test "encode polygon geohashes" do
    polygon = %{coordinates: [{16.76513671875, 52.42587274336118}, {16.827621459960938, 52.33114320164082}, {16.967010498046875, 52.39403946901232}, {17.123565673828125, 52.391106301345005}, {16.941604614257813, 52.53376701989025}, {16.76513671875, 52.42587274336118}]}
    geohashes = ["u3k4b", "u3k4c", "u3k4f", "u37fx", "u3k48", "u3k49", "u3k4d", "u3k4e", "u37fm", "u37fq", "u37fr", "u3k42", "u3k43", "u3k46", "u3k47", "u3k4k", "u37fj", "u37fn", "u37fp", "u3k40", "u3k41", "u3k44", "u3k45", "u3k4h", "u3k4j", "u37cy", "u37cz", "u3k1b", "u3k1c", "u37cw", "u37cx"]
    assert geohashes == Geobox.encode_geohashes(polygon, 5)
  end

  test "decode bounding box from geohash" do
    assert [16.875, 52.470703125, 16.8310546875, 52.4267578125] == Geobox.decode_box("u37fr")
  end
end
