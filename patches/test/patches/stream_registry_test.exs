defmodule Patches.StreamRegistryTest do
  use ExUnit.Case
  doctest Patches.StreamRegistry

  alias Patches.StreamRegistry, as: Registry
  alias Patches.StreamRegistry.SessionState

  test "managing a new stream for a collection creates a cache window" do
    %{ caches: %{ "ubuntu:18.04" => %{ view: _view } } } =
      Registry.register_sessions(
        Registry.init(),
        platform: "ubuntu:18.04",
        collection: [1,2,3,4,5],
        sessions: @test_sessions)
  end

  test "managing a new stream for a collection create session states" do
    test_id =
      @test_sessions
      |> Enum.at(0)
      |> Map.get(:id)

    %{ sessions: %{ ^test_id  => %SessionState{} } } =
      Registry.register_sessions(
        Registry.init(),
        platform: "ubuntu:18.04",
        collection: [1,2,3,4,5],
        sessions: @test_sessions)
  end

  test "can retrieve the view over the collection managed by a cache" do
    test_id =
      @test_sessions
      |> Enum.at(0)
      |> Map.get(:id)

    view =
      Registry.init()
      |> Registry.register_sessions(
        platform: "ubuntu:18.04",
        collection: [1,2,3,4,5],
        sessions: @test_sessions)
      |> Registry.cache_lookup("ubuntu:18.04", test_id)

    assert view == [1,2,3,4,5]
  end

  test "can retrieve a limited number of items from a cache's view" do
    test_id =
      @test_sessions
      |> Enum.at(0)
      |> Map.get(:id)

    view =
      Registry.init()
      |> Registry.register_sessions(
        platform: "ubuntu:18.04",
        collection: [1,2,3,4,5],
        sessions: @test_sessions)
      |> Registry.cache_lookup("ubuntu:18.04", test_id, 3)

    assert view == [1,2,3]
  end
  
  test "can configure the `Registry` to maintain a limited window size" do
    test_id =
      @test_sessions
      |> Enum.at(0)
      |> Map.get(:id)

    view =
      Registry.init()
      |> Registry.register_sessions(
        platform: "ubuntu:18.04",
        collection: [1,2,3,4,5],
        sessions: @test_sessions,
        window_length: 3)
      |> Registry.cache_lookup("ubuntu:18.04", test_id)

    assert view == [1,2,3]
  end

  test "can update the cache maintained for a given platform" do
    %{ caches: %{ "ubuntu:18.04" => %{ collection: "worked" } } } =
      Registry.init()
      |> Registry.register_sessions(
          platform: "ubuntu:18.04",
          collection: [1,2,3,4,5],
          sessions: @test_sessions)
      |> Registry.update_cache("ubuntu:18.04", fn cache -> %{ cache | collection: "worked" } end)
  end

  test "can update the state of a given session" do
    test_id =
      @test_sessions
      |> Enum.at(0)
      |> Map.get(:id)
    
    %{ sessions: %{ ^test_id => %{ platform: "overwritten" } } } =
      Registry.init()
      |> Registry.register_sessions(
          platform: "ubuntu:18.04",
          collection: [1,2,3,4,5],
          sessions: @test_sessions)
      |> Registry.update_session(test_id, fn session -> %{ session | platform: "overwritten"} end)
  end
  
  test "updating without a function argument shifts the cache window for a platform forward" do
    %{ caches: %{ "ubuntu:18.04" => %{ start_index: start_index } } } =
      Registry.init()
      |> Registry.register_sessions(
          platform: "ubuntu:18.04",
          collection: [1,2,3,4,5],
          sessions: @test_sessions)
      |> Registry.update_cache("ubuntu:18.04")

    assert start_index > 0
  end
  
  test "updating with an integer argument moves a session's window index forward" do
    test_id =
      @test_sessions
      |> Enum.at(0)
      |> Map.get(:id)
    
    %{ sessions: %{ ^test_id => %{ window_index: window_index } } } =
      Registry.init()
      |> Registry.register_sessions(
          platform: "ubuntu:18.04",
          collection: [1,2,3,4,5],
          sessions: @test_sessions)
      |> Registry.update_session(test_id)

    assert window_index > 0
  end
end
