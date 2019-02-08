defmodule Patches.StreamManager.Config do
  @moduledoc """
  Configuration for a `Patches.StreamManager`.
  """

  defstruct(
    default_window_length: 32,
    shift_rate: 32,
  )
end

defmodule Patches.StreamManager.SessionState do
  @moduledoc """
  Representation of the state of a scanner session being managed by a
  `Patches.StreamManager`.
  """

  defstruct [
    :platform,
    :current_index,
    :window_length,
    :last_read_at,
  ]
end

defmodule Patches.StreamManager do
  @moduledoc """
  An `Agent` responsible for managing cache windows over lists of
  vulnerabilities being streamed from a `Source`.
  """

  use Agent

  alias Patches.StreamManager.SessionState
  alias Patches.CacheWindow

  @doc """
  Start and link the `StreamManager`.
  """
  def start_link(config) do
    init =
      %{
        config: config,
        caches: %{},
        sessions: %{},
      }

    Agent.start_link(fn -> init end, name: __MODULE__)
  end

  @doc """
  Remove any currently managed sessions and replace them with a new collection
  thereof.

  ## Arguments
  
  1. `sessions` is a list of `Patches.Server.Session`.
  3. `create_cache` is a function that, given a platform string, constructs a
  `Patches.CacheWindow`.
  """
  def manage(sessions, create_cache) when is_function(create_cache) do
    Agent.update(__MODULE__, fn %{ config: cfg } ->
      caches =
        sessions
        |> Enum.map(fn %{ platform: platform } -> platform end)
        |> Enum.uniq()
        |> Enum.map(fn platform -> {platform, create_cache.(platform)} end)
        |> Enum.into(%{})

      session_states =
        for %{ id: id, platform: platform } <- sessions,
            state = %SessionState{
              platform: platform,
              current_index: 0,
              window_length: cfg.default_window_length,
              last_read_at: Time.utc_now(),
            },
            into: %{},
            do: {id, state}

      %{
        config: cfg,
        caches: caches,
        sessions: session_states,
      }
    end)
  end

  @doc """
  Retrieve information about the states of sessions belonging to scanners
  running a scan for a particular platform.
  """
  def sessions(platform) when is_binary(platform) do
    Agent.get(__MODULE__, fn %{ sessions: sessions } ->
      sessions
      |> Map.values()
      |> Enum.filter(fn %{ platform: pform } -> pform == platform end)
    end)
  end

  @doc """
  Retrieve data from the cache being managed for a particular scanner session.
  """
  def retrieve(session_id) when is_binary(session_id) do
    Agent.get_and_update(__MODULE__, fn state ->
      with session <- state.sessions[session_id],
           session != nil,
           cache <- Map.get(state.caches, session.platform),
           cache != nil
      do
        vulns =
          Window.view(
            cache.view,
            session.current_index,
            state.config.default_window_length)

        new_sessions =
          Map.update(state.sessions, session_id, session, fn %{ current_index: i } ->
            %{ session | current_index: i + Enum.count(vulns) }
          end)

        new_state =
          %{ state | sessions: new_sessions }

        {vulns, new_state}
      else
        _ ->
          {[], state}
      end
    end)
  end

  @doc """
  Determine if all scanners whose sessions are being managed by the
  `StreamManager` are complete.
  """
  def all_sessions_complete?() do
    Agent.get(__MODULE__, fn %{ caches: caches } ->
      caches
      |> Map.keys()
      |> Enum.map(&all_sessions_complete?/1)
      |> Enum.all?()
    end)
  end

  @doc """
  Determine if all of the sessions for scanners retrieving vulnerabilities for a
  particular platform are complete.
  """
  def all_sessions_complete?(platform) when is_binary(platform) do
    platform
    |> sessions()
    |> all_sessions_complete?()
  end

  def all_sessions_complete?(session_states) do
    Agent.get(__MODULE__, fn %{ caches: caches } ->
      session_states
      |> Enum.map(fn %{ platform: p, current_index: i } -> {p, i} end)
      |> Enum.map(fn {p, i} -> all_sessions_complete?(caches, p, i) end)
      |> Enum.all?()
    end)
  end

  defp all_sessions_complete?(caches, platform, index) do
    case caches[platform] do
      %{ view: [], start_index: i } ->
        index >= i

      _ ->
        false
    end
  end
end
