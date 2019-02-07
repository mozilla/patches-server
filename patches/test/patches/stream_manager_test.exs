defmodule Patches.StreamManagerTest do
  use ExUnit.Case, async: true
  doctest Patches.StreamManager

  alias Patches.StreamManager, as: Manager
  alias Patches.StreamManager.Config
  alias Patches.Server.Session
  alias Patches.CacheWindow

  setup do
    config =
      %Config{ default_window_length: 3 }

    {:ok, pid} =
      Patches.StreamManager.start_link(config)
    
    sessions =
      [
        %Session{ platform: "ubuntu:18.04", id: "test1", created_at: Time.utc_now() },
        %Session{ platform: "ubuntu:18.04", id: "test2", created_at: Time.utc_now() },
        %Session{ platform: "alpine:3.4", id: "test3", created_at: Time.utc_now() },
      ]

    %{
      pid: pid,
      sessions: sessions,
    }
  end

  test "can initialize cache windows for a collection of sessions", %{ sessions: sessions } do
    :ok =
      sessions
      |> Manager.manage(fn _platform -> CacheWindow.init([1,2,3,4,5], 3) end)
  end

  test "initializing caches for new sessions removes the old sessions", %{ sessions: sessions } do
    Manager.manage(sessions, fn _platform -> CacheWindow.init([1,2,3,4,5], 3) end)

    assert Enum.count(Manager.sessions("ubuntu:18.04")) == 2
    assert Enum.count(Manager.sessions("alpine:3.4")) == 1

    new_sessions =
      [
        %Session{ platform: "debian:unstable", id: "test3", created_at: Time.utc_now() },
      ]
    
    Manager.manage(new_sessions, fn _platform -> CacheWindow.init([1,2,3,4,5], 3) end)
    
    assert Enum.count(Manager.sessions("ubuntu:18.04")) == 0
    assert Enum.count(Manager.sessions("alpine:3.4")) == 0
    
    assert Enum.count(Manager.sessions("debian:unstable")) == 1
  end

  test "cache contents can be fetched for individual session owners", %{ sessions: sessions } do
    Manager.manage(sessions, fn _platform -> CacheWindow.init([1,2,3,4,5], 3) end)

    assert Manager.retrieve("test1") == [1,2,3]
    assert Manager.retrieve("test2") == [1,2,3]
  end

  test "the window only slides forward after all sessions read all data", %{ sessions: sessions } do
    Manager.manage(sessions, fn _platform -> CacheWindow.init([1,2,3,4,5], 3) end)

    Manager.retrieve("test1")
    assert Manager.retrieve("test1") == []

    Manager.retrieve("test2")

    assert Manager.retrieve("test1") == [4,5]
    assert Manager.retrieve("test2") == [4,5]
  end

  test "can query to determine whether all sessions are complete or not", %{ sessions: sessions } do
    Manager.manage(sessions, fn _platform -> CacheWindow.init([1,2,3,4,5], 3) end)
    Manager.retrieve("test1")
    Manager.retrieve("test1")
    Manager.retrieve("test2")
    Manager.retrieve("test2")
    Manager.retrieve("test3")
    Manager.retrieve("test3")

    assert Manager.all_sessions_complete?("ubuntu:18.04")
    assert Manager.all_sessions_complete?("alpine:3.4")
  end
end
