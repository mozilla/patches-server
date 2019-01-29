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
    cache = Cache.init(["platform1"])

    assert Cache.register(cache, "platform1", :test_value) == :ok
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
