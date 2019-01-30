defmodule Patches.Server.CacheTest do
  use ExUnit.Case
  doctest Patches.Server.Cache

  alias Patches.Server.Cache

  test "must be constructed with a starting list of bucket names" do
    cache = Cache.init(["platform1", "platform2"])

    assert Map.has_key?(cache, "platform1")
    assert Map.has_key?(cache, "platform2")
  end

  test "can register values into the cache" do
    cache =
      Cache.init(["platform1"])
      |> Cache.register("platform1", :test_value)

    assert Enum.count(cache["platform1"]) == 1
  end

  test "cannot retrieve values from buckets that do not exist" do
    vulns =
      Cache.init(["platform1"])
      |> Cache.retrieve("platform2", 0)

    assert vulns == []
  end

  test "can retrieve values registered to the cache but does not guarantee order" do
    vulns =
      Cache.init(["p1"])
      |> Cache.register("p1", :v1)
      |> Cache.register("p1", :v2)
      |> Cache.retrieve("p1")

    both_found =
      case vulns do
        [:v1, :v2] ->
          true

        [:v2, :v1] ->
          true

        _ ->
          false
      end

    assert both_found
  end

  test "can sort lists of values in a cache" do
    vulns =
      Cache.init(["p1"])
      |> Cache.register("p1", 9)
      |> Cache.register("p1", 2)
      |> Cache.register("p1", 8)
      |> Cache.register("p1", 3)
      |> Cache.register("p1", 1)
      |> Cache.sort_by(fn x -> x end)
      |> Cache.retrieve("p1")

    assert vulns == [1, 2, 3, 8, 9]
  end

  test "can enforce size constraints on caches" do
    vulns =
      Cache.init(["p1"])
      |> Cache.register("p1", 9)
      |> Cache.register("p1", 2)
      |> Cache.register("p1", 8)
      |> Cache.register("p1", 3)
      |> Cache.register("p1", 1)
      |> Cache.restrict(fn _cache_size -> 3 end)
      |> Cache.retrieve("p1")

    assert vulns == [1, 3, 8]
  end

  test "applying a size constraint greater than the cache size has no effect" do
    vulns =
      Cache.init(["p1"])
      |> Cache.register("p1", 9)
      |> Cache.register("p1", 2)
      |> Cache.register("p1", 8)
      |> Cache.restrict(fn _cache_size -> 5 end)
      |> Cache.retrieve("p1")

    assert vulns == [8, 2, 9]
  end

  test "constraints can be computed to enforce particular management policies" do
    cache =
      Cache.init(["p1", "p2", "p3"])
      |> Cache.register("p1", 9)
      |> Cache.register("p1", 2)
      |> Cache.register("p1", 8)
      |> Cache.register("p1", 3)
      |> Cache.register("p2", 0)
      |> Cache.register("p2", 1)
      |> Cache.register("p3", 5)
      |> Cache.register("p3", 4)
      |> Cache.register("p3", 7)
      |> Cache.restrict(fn cache_size ->
        (cache_size) / 2 |> :math.floor |> Kernel.trunc
      end)

    [p1, p2, p3] = Enum.map(["p1", "p2", "p3"], fn platform ->
      Cache.retrieve(cache, platform)
    end)

    assert p1 == [3, 8]
    assert p2 == [1]
    assert p3 == [7]
  end

  test "can get the sizes of each cache to make sizing decisions about" do
    %{"p1" => p1, "p2" => p2, "p3" => p3} =
      Cache.init(["p1", "p2", "p3"])
      |> Cache.register("p1", 9)
      |> Cache.register("p1", 2)
      |> Cache.register("p1", 8)
      |> Cache.register("p1", 3)
      |> Cache.register("p2", 0)
      |> Cache.register("p2", 1)
      |> Cache.register("p3", 5)
      |> Cache.register("p3", 4)
      |> Cache.register("p3", 7)
      |> Cache.sizes

    assert p1 == 4
    assert p2 == 2
    assert p3 == 3
  end
end
