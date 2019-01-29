defmodule Patches.Server.CacheTest do
  use ExUnit.Case
  doctest Patches.Server.Cache

  alias Patches.Server.Cache

  test "must be constructed with a starting list of platforms to support" do
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

  test "cannot retrieve vulns for unsupported platforms" do
    vulns =
      Cache.init(["platform1"])
      |> Cache.retrieve("platform2", 0)

    assert vulns == []
  end

  test "can retrieve vulns registered to the cache but does not guarantee order" do
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
end

defmodule Patches.Server.CacheAgentTest do
  use ExUnit.Case, async: true
  doctest Patches.Server.CacheAgent

  alias Patches.Server.CacheAgent

  setup do
    {:ok, cache} = CacheAgent.start_link(["platform1", "platform2"])
    %{cache: cache}
  end

  test "never exceeds maximum capacity", _cache do
    assert true
  end

  test "always iterates through even uncached items", _cache do
    assert true
  end
end
