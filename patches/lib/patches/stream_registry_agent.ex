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
  def start_link(config, stream_registry) do
    init =
      %{
        config: config,
        registry: stream_registry,
      }

    Agent.start_link(fn -> init end, name: __MODULE__)
  end

  @doc """
  Create a new cache window over a provided `collection` identified by `platform`.
  Only the given `sessions` will be granted access to values in this collection.
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
end
