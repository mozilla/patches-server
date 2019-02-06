defmodule Patches.StreamManager.Config do
  @moduledoc """
  Configuration for a `Patches.StreamManager`.
  """

  defstruct(
    default_window_length: 32,
  )
end

defmodule Patches.StreamManager.SessionState do
  @moduledoc """
  Representation of the state of a scanner session being managed by a
  `Patches.StreamManager`.
  """

  defstruct [
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

  @doc """
  Start and link the `StreamManager`.
  """
  def start_link(config) do
    init =
      %{
        config: config,
        caches: %{},
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
      session_start_state =
        %SessionState{
          current_index: 0,
          window_length: cfg.default_window_length,
          last_read_at: Time.utc_now(),
        }

      caches =
        Enum.reduce(sessions, %{}, fn (session, caches) ->
          default_record =
            %{
              cache: create_cache.(session.platform),
              sessions: %{
                session.id => session_start_state,
              },
            }

          add_session =
            fn %{ cache: c, sessions: s } ->
              %{
                cache: c,
                sessions: Map.put(s, session.id, session_start_state),
              }
            end

          Map.update(caches, session.platform, default_record, add_session)
        end)

      reverse_lookup_table =
        for session <- sessions,
            into: %{},
            do: {session.id, session.platform}

      %{
        config: cfg,
        caches: caches,
        scanners: reverse_lookup_table,
      }
    end)
  end

  @doc """
  Retrieve information about the states of sessions belonging to scanners
  running a scan for a particular platform.
  """
  def sessions(platform) when is_binary(platform) do
    Agent.get(__MODULE__, fn
      %{ caches: %{ ^platform => %{ sessions: sessions } } } ->
        sessions

      _ ->
        []
    end)
  end

  @doc """
  Retrieve data from the cache being managed for a particular scanner session.
  """
  def retrieve(session_id) when is_binary(session_id) do
  end

  @doc """
  Determine if all scanners whose sessions are being managed by the
  `StreamManager` are complete.
  """
  def all_sessions_complete?() do
  end

  @doc """
  Determine if all of the sessions for scanners retrieving vulnerabilities for a
  particular platform are complete.
  """
  def all_sessions_complete?(platform) when is_binary(platform) do
  end
end
