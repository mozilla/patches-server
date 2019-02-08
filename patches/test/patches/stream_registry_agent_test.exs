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
end
