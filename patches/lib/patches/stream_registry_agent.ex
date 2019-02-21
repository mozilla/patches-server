defmodule Patches.StreamRegistry.Agent.Config do
  @moduledoc """
  A struct type providing named fields for configuration parameters
  that we would like to supply as defaults to the `Agent`.

  * `max_window_length` defines the maximum number of vulnerabilities
  each `CacheWindow` will be allowed to hold.
  * `lookup_limit` defines the maximum number of vulnerabilities to
  retrieve with each `cache_lookup`.
  """

  defstruct(
    max_window_length: 8000,
    lookup_limit: 128
  )
end

defmodule Patches.StreamRegistry.Agent do
  @moduledoc """
  """

  use Agent
  
  alias Patches.StreamRegistry, as: Registry

  @doc """
  Start a link to an `Agent` maintaining a given `StreamRegistry`.
  """
  def start_link(config) do
    init =
      %{
        config: config,
        registry: Registry.init(),
      }

    Agent.start_link(fn -> init end, name: __MODULE__)
  end

  @doc """
  Create a new cache window over a provided `collection` identified by `platform`.
  Only the given `sessions` will be granted access to values in this collection.

  ## Arguments

  1. `platform` is the name of the platform to get vulns for, e.g. ubuntu:18.04
  2. `collection` is the collection of vulns to create a window over
  3. `sessions` is a list of session IDs
  """
  def register_sessions(platform, collection, sessions) do
    %{ max_window_length: limit } =
      Agent.get(__MODULE__, fn %{ config: cfg } -> cfg end)
      
    register_sessions(platform, collection, sessions, limit)
  end
 
  @doc """
  Create a new cache window with a maximum `window_length`.
  """
  def register_sessions(platform, collection, sessions, window_length) do
    Agent.update(__MODULE__, fn state=%{ registry: reg } ->
      new_registry =
        Registry.register_sessions(
          reg,
          platform: platform,
          collection: collection,
          sessions: sessions,
          window_length: window_length)

      %{ state | registry: new_registry }
    end)
  end

  @doc """
  Retrieve values from the cache being read by the specified session.
  The list of values returned will be offset by the session's current index
  into the window.
  """
  def retrieve(session_id) do
    %{ lookup_limit: limit } =
      Agent.get(__MODULE__, fn %{ config: cfg } -> cfg end)
    
    retrieve(session_id, limit)
  end

  @doc """
  Retrieve up to `limit` values from the cache being read by a specific session.

  Calls to `retrieve` also have the effect of updating the state for the
  session in question, resulting in successive calls returning successive
  items from the window.
  """
  def retrieve(session_id, limit) do
    Agent.get_and_update(__MODULE__, fn state=%{ registry: reg } ->
      values =
        Registry.cache_lookup(reg, session_id, limit)

      new_state =
        %{
          state |
          registry: Registry.update_session(reg, session_id, Enum.count(values))
        }

      {values, new_state}
    end)
  end

  @doc """
  Shift a cache window forward.
  """
  def update_cache(platform) do
    Agent.update(__MODULE__, fn %{ config: cfg, registry: reg } ->
      %{
        config: cfg,
        registry: Registry.update_cache(reg, platform, cfg.max_window_length),
      }
    end)
  end

  @doc """
  Update the collections being managed by each cache with a given `update_fn`.

  The provided `update_fn` will be called with:

  1. The name of the platform identifying the cache being updated and
  2. The collection being managed by the cache in question

  and is expected to return a new collection.

  This function will compute a new view over the returned collection using
  the `start_index` and window `length` from the state of the existing cache.
  """
  def update_caches(update_fn) when is_function(update_fn) do
    Agent.update(__MODULE__, fn state=%{ registry: reg } ->
      new_registry =
        Enum.reduce(Map.keys(reg.caches), reg, fn (platform, registry) ->
          Registry.update_cache(registry, platform, fn cache ->
            new_collection =
              update_fn.(platform, cache.collection)

            new_view =
              Window.view(new_collection, cache.start_index, cache.length)

            %{ cache | collection: new_collection, view: new_view }
          end)
        end)

      %{ state | registry: new_registry }
    end)
  end

  @doc """
  Determine whether all of the scanners with active sessions have read
  all of the vulnerabilities available in their respective caches.
  """
  def all_sessions_complete?() do
    Agent.get(__MODULE__, fn %{ registry: reg } ->
      Registry.all_sessions_complete?(reg)
    end)
  end

  @doc """
  Determine whether all of the scanners reading vulnerabilities
  for a specific platform have read everything currently available.
  """
  def all_sessions_complete?(platform) do
    Agent.get(__MODULE__, fn %{ registry: reg } ->
      Registry.all_sessions_complete?(reg, platform)
    end)
  end

  @doc """
  Remove a specific session from the stream registry.
  """
  def terminate_session(session_id) do
    Agent.update(__MODULE__, fn state=%{ registry: reg } ->
      Registry.terminate_session(reg, session_id)
    end)
  end
end
