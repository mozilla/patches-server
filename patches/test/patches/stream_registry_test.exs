defmodule Patches.StreamRegistryTest do
  use ExUnit.Case
  doctest Patches.StreamRegistry

  alias Patches.StreamRegistry, as: Registry
  alias Patches.StreamRegistry.SessionState

  @test_sessions [
    %Patches.Server.Session{ platform: "ubuntu:18.04", id: "test1" },
    %Patches.Server.Session{ platform: "ubuntu:18.04", id: "test2" },
    %Patches.Server.Session{ platform: "alpine:3.4", id: "test3" },
  ]

  def init_registry(window_len \\ 5) do
    sorted =
      Enum.reduce(@test_sessions, %{}, fn (session, mapping) ->
        Map.update(mapping, session.platform, [ session ], fn sessions ->
          [ session | sessions ]
        end)
      end)

    Enum.reduce(sorted, Registry.init(), fn ({platform, sessions}, reg) ->
      Registry.register_sessions(
        reg,
        platform: platform,
        collection: [1,2,3,4,5],
        sessions: Enum.map(sessions, &Map.get(&1, :id)),
        window_length: window_len)
    end)
  end

  test "managing a new stream for a collection creates a cache window" do
    %{ caches: %{ "ubuntu:18.04" => %{ view: _view } } } =
      init_registry()
  end

  test "managing a new stream for a collection create session states" do
    test_id =
      @test_sessions
      |> Enum.at(0)
      |> Map.get(:id)

    %{ sessions: %{ ^test_id  => %SessionState{} } } =
      init_registry()
  end

  test "can retrieve the view over the collection managed by a cache" do
    test_id =
      @test_sessions
      |> Enum.at(0)
      |> Map.get(:id)

    view =
      init_registry()
      |> Registry.cache_lookup(test_id)

    assert view == [1,2,3,4,5]
  end

  test "can retrieve a limited number of items from a cache's view" do
    test_id =
      @test_sessions
      |> Enum.at(0)
      |> Map.get(:id)

    view =
      init_registry()
      |> Registry.cache_lookup(test_id, 3)

    assert view == [1,2,3]
  end
  
  test "can configure the `Registry` to maintain a limited window size" do
    test_id =
      @test_sessions
      |> Enum.at(0)
      |> Map.get(:id)

    view =
      init_registry(3)
      |> Registry.cache_lookup(test_id)

    assert view == [1,2,3]
  end

  test "can update the cache maintained for a given platform" do
    %{ caches: %{ "ubuntu:18.04" => %{ collection: "worked" } } } =
      Registry.update_cache(init_registry(), "ubuntu:18.04", fn cache ->
        %{ cache | collection: "worked" }
      end)
  end

  test "can update the state of a given session" do
    test_id =
      @test_sessions
      |> Enum.at(0)
      |> Map.get(:id)
    
    %{ sessions: %{ ^test_id => %{ platform: "overwritten" } } } =
      Registry.update_session(init_registry(), test_id, fn session ->
        %{ session | platform: "overwritten"}
      end)
  end
  
  test "updating without a function argument shifts the cache window for a platform forward" do
    %{ caches: %{ "ubuntu:18.04" => %{ start_index: start_index } } } =
      Registry.update_cache(init_registry(), "ubuntu:18.04")

    assert start_index > 0
  end
  
  test "updating with an integer argument moves a session's window index forward" do
    test_id =
      @test_sessions
      |> Enum.at(0)
      |> Map.get(:id)
    
    %{ sessions: %{ ^test_id => %{ window_index: window_index } } } =
      Registry.update_session(init_registry(), test_id, 2)

    assert window_index > 0
  end

  test "can query to determine if a session is complete" do
    test_id =
      @test_sessions
      |> Enum.at(0)
      |> Map.get(:id)
  
    complete? =
      Registry.session_complete?(init_registry(), test_id)

    assert not complete?
  end

  test "a session is reported as complete after it has read all the items in a window" do
    test_id =
      @test_sessions
      |> Enum.at(0)
      |> Map.get(:id)
  
    complete? =
      init_registry()
      |> Registry.update_session(test_id, 5)
      |> Registry.session_complete?(test_id)

    assert complete?
  end

  test "can query to determine if all sessions are complete" do
    assert not Registry.all_sessions_complete?(init_registry())
  end
  
  test "all sessions are reported as complete after they have read all the items in a window" do
    registry =
      init_registry()

    updated_registry =
      @test_sessions
      |> Enum.map(&Map.get(&1, :id))
      |> Enum.reduce(registry, fn (id, reg) -> Registry.update_session(reg, id, 5) end)

    assert Registry.all_sessions_complete?(updated_registry)
  end

  test "can query to determine if all sessions reading from a specific cache are complete" do
    assert not Registry.all_sessions_complete?(init_registry(), "ubuntu:18.04")
  end
  
  test "sessions reading from a specific cache are reported complete after reading all content" do
    registry =
      init_registry()

    updated_registry =
      @test_sessions
      |> Enum.filter(fn %{ platform: pform } -> pform == "ubuntu:18.04" end)
      |> Enum.map(&Map.get(&1, :id))
      |> Enum.reduce(registry, fn (id, reg) -> Registry.update_session(reg, id, 5) end)

    all_complete? =
      Registry.all_sessions_complete?(updated_registry, "ubuntu:18.04")

    assert all_complete?
  end
end
