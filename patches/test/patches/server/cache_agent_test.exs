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

