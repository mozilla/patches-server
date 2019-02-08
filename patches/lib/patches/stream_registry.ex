defmodule Patches.StreamRegistry.SessionState do
  @moduledoc """
  Representation of the state of a scanner session being managed by a
  `Patches.StreamManager`.
  """

  defstruct [
    :platform,
    :window_index,
    :last_read_at,
  ]
end

defmodule Patches.StreamRegistry do
  @moduledoc """
  A data structure representing the state of a registry system tracking
  the states of streams for scanners with active sessions.

  ## Representation

  ```elixir
  %{
    caches: %{
      "platform 1" => CacheWindow,
      "platform 2" => CacheWindow,
    },
    sessions: %{
      "session id 1" => SessionState,
      "session id 2" => SessionState,
    }
  }
  ```
  """
  
  @default_window_length 32

  alias Patches.StreamRegistry.SessionState
  alias Patches.CacheWindow

  @doc """
  Initialize an empty registry.
  """
  def init() do
    %{
      caches: %{},
      sessions: %{},
    }
  end
  
  def register_sessions(%{ caches: caches, sessions: sessions }, [
    platform: platform,
    collection: collection,
    sessions: new_sessions,
    window_length: window_length,
  ]) do
    new_cache =
      CacheWindow.init(collection, window_length)

    new_session_states =
      for %{ id: id } <- new_sessions,
          state = %SessionState{
            platform: platform,
            window_index: 0,
            last_read_at: Time.utc_now(),
          },
          into: %{},
          do: {id, state}

    %{
      caches: Map.put(caches, platform, new_cache),
      sessions: Map.merge(sessions, new_session_states),
    }
        
  end

  def register_sessions(registry, [
    platform: platform,
    collection: collection,
    sessions: sessions,
  ]) do
    register_sessions(registry, [
      platform: platform,
      collection: collection,
      sessions: sessions,
      window_length: @default_window_length,
    ])
  end

  def cache_lookup(registry, platform, session_id) do
    cache_lookup(registry, platform, session_id, @default_window_length)
  end

  def cache_lookup(registry, platform, session_id, limit) do
    with cache <- registry.caches[platform],
         cache != nil,
         session <- registry.sessions[session_id],
         session != nil
    do
      cache.view
      |> Window.view(session.window_index, limit)
    else
      _ ->
        []
    end
  end

  def update_cache(registry, platform, update_fn) when is_function(update_fn) do
    case Map.get(registry.caches, platform) do
      nil ->
        registry

      cache ->
        %{ registry | caches: Map.update(registry.caches, platform, cache, update_fn) }
    end
  end

  def update_cache(registry, platform, shift_amount \\ @default_window_length) do
    update_cache(registry, platform, &CacheWindow.shift_right(&1, shift_amount))
  end

  def update_session(registry, session_id, update_fn) when is_function(update_fn) do
    case Map.get(registry.sessions, session_id) do
      nil ->
        registry

      session ->
        %{ registry | sessions: Map.update(registry.sessions, session_id, session, update_fn) }
    end
  end

  def update_session(registry, session_id, shift_by) when is_integer(shift_by) do
    update_session(registry, session_id, fn session=%{ window_index: i } ->
      %{ session | window_index: i + shift_by }
    end)
  end
end
