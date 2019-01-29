defmodule Patches.Server.CacheTest do
  use ExUnit.Case
  doctest Patches.Server.Cache

  alias Patches.Server.Cache

  test "must be constructed with a starting list of platforms to support" do
    cache1 = Cache.init(["platform1", "platform2"])

    assert Map.has_key?(cache1, "platform1")
    assert Map.has_key?(cache1, "platform2")
  end

  test "never exceeds maximum capacity" do
  end

  test "always iterates through even uncached items" do
  end
end
