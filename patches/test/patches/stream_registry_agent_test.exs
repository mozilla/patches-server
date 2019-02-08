defmodule Patches.StreamRegistry.AgentTest do
  use ExUnit.Case, async: true
  doctest Patches.StreamRegistry.Agent

  alias Patches.StreamRegistry, as: Registry
  alias Patches.StreamRegistry.Agent, as: SRAgent
  alias Patches.StreamRegistry.Agent.Config

  setup do
    config =
      %Config{
        max_window_length: 10,
        lookup_limit: 10,
      }

    {:ok, pid} =
      SRAgent.start_link(config, Registry.init())

    %{
      config: config,
      pid: pid,
    }
  end

  test "can instruct to activated sessions" do
    sessions =
      [
        %Patches.Server.Session{ platform: "discarded", id: "test1" },
        %Patches.Server.Session{ platform: "discarded", id: "test2" },
      ]

    assert SRAgent.register_sessions("ubuntu:18.04", [1,2,3,4,5], sessions) == :ok
  end

  test "can retrieve values from an appropriate cache" do
    sessions1 =
      [
        %Patches.Server.Session{ platform: "discarded", id: "test1" },
        %Patches.Server.Session{ platform: "discarded", id: "test2" },
      ]
    
    sessions2 =
      [
        %Patches.Server.Session{ platform: "discarded", id: "test3" },
        %Patches.Server.Session{ platform: "discarded", id: "test4" },
      ]
    
    SRAgent.register_sessions("ubuntu:18.04", [1,2,3,4,5], sessions1)
    SRAgent.register_sessions("alpine:3.4", [6,7,8], sessions2)

    assert SRAgent.retrieve("test1") == [1,2,3,4,5]
    assert SRAgent.retrieve("test4") == [6,7,8]
  end

  test "can limit the maximum window size over a collection when sessions are registered" do
    sessions =
      [
        %Patches.Server.Session{ platform: "discarded", id: "test1" },
        %Patches.Server.Session{ platform: "discarded", id: "test2" },
      ]

    SRAgent.register_sessions("ubuntu:18.04", [1,2,3,4,5], sessions, 3)

    assert SRAgent.retrieve("test1") == [1,2,3]
    assert SRAgent.retrieve("test2") == [1,2,3]
  end

  test "can limit the number of values retrieved from a cache" do
    sessions =
      [
        %Patches.Server.Session{ platform: "discarded", id: "test1" },
        %Patches.Server.Session{ platform: "discarded", id: "test2" },
      ]

    SRAgent.register_sessions("ubuntu:18.04", [1,2,3,4,5], sessions)

    assert SRAgent.retrieve("test1", 1) == [1]
    assert SRAgent.retrieve("test2", 2) == [1,2]
  end

  test "multiple calls to retrieve progress through the cache window" do
    sessions =
      [
        %Patches.Server.Session{ platform: "discarded", id: "test1" },
        %Patches.Server.Session{ platform: "discarded", id: "test2" },
      ]

    SRAgent.register_sessions("ubuntu:18.04", [1,2,3,4,5], sessions)

    assert SRAgent.retrieve("test1", 1) == [1]
    assert SRAgent.retrieve("test1", 2) == [2,3]
  end

  test "after reading an entire window, calls to retrieve return an empty list" do
    sessions =
      [
        %Patches.Server.Session{ platform: "discarded", id: "test1" },
        %Patches.Server.Session{ platform: "discarded", id: "test2" },
      ]

    SRAgent.register_sessions("ubuntu:18.04", [1,2,3,4,5], sessions)
    SRAgent.retrieve("test1")

    assert SRAgent.retrieve("test1") == []
  end

  test "can update the collection maintained by a cache identified by a platform" do
    session =
      %Patches.Server.Session{ platform: "discarded", id: "test1" }

    SRAgent.register_sessions("ubuntu:18.04", [1,2,3], [session])
    
    SRAgent.update_caches(fn (_platform, _coll) -> [4,5] end)

    assert SRAgent.retrieve("test1") == [4,5]
  end
  
  test "after updating a cache's collection, the view retains our previous position" do
    session =
      %Patches.Server.Session{ platform: "discarded", id: "test1" }

    SRAgent.register_sessions("ubuntu:18.04", [1,2,3,4,5], [session])
    SRAgent.retrieve("test1", 2)
    
    SRAgent.update_caches(fn (_platform, _coll) -> [10,11,12,13,14,15] end)

    assert SRAgent.retrieve("test1") == [12,13,14,15]
  end

  test "can update caches in different ways depending on the platform identifying them" do
    session1 =
      %Patches.Server.Session{ platform: "discarded", id: "test1" }
    
    session2 =
      %Patches.Server.Session{ platform: "discarded", id: "test2" }

    SRAgent.register_sessions("ubuntu:18.04", [1,2,3], [session1])
    SRAgent.register_sessions("alpine:3.4", [1,2,3], [session2])
   
    SRAgent.update_caches(fn
      ("ubuntu:18.04", collection) ->
        [4,5]

      (_platform, coll) ->
        coll
    end)

    assert SRAgent.retrieve("test1") == [4,5]
    assert SRAgent.retrieve("test2") == [1,2,3]
  end
end
