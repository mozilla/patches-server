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

  def register_sessions(platform, collection, sessions) do
    %{ max_window_length: limit } =
      Agent.get(__MODULE__, fn %{ config: cfg } -> cfg end)
      
    register_sessions(platform, collection, sessions, limit)
  end
  
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

  def retrieve(session_id) do
    %{ lookup_limit: limit } =
      Agent.get(__MODULE__, fn %{ config: cfg } -> cfg end)
    
    retrieve(session_id, limit)
  end

  def retrieve(session_id, limit) do
    Agent.get(__MODULE__, fn %{ registry: reg } ->
      Registry.cache_lookup(reg, session_id, limit)
    end)
  end
end
