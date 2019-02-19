defmodule Patches.Server.Session do
  @moduledoc """
  A structure representing a scanner session.
  """

  @enforce_keys [:platform]
  defstruct [
    :platform,
    :id,
    :created_at
  ]
end

defmodule Patches.Server do
  @moduledoc """
  Tracks sessions belonging to scanners requesting vulnerability information.
  """

  @doc """
  Construt an empty `Patches.Server`.
  """
  def init() do
    %{
      active_sessions: %{},
      queued_sessions: %{},
    }
  end

  @doc """
  Enqueue a new session for a scanner wishing to retrieve information about
  vulnerabilities affecting packages for a particular platform.
  """
  def queue_session(server, platform, session_id) do
    new_session =
      %Patches.Server.Session{
        platform: platform,
        id: session_id,
        created_at: Time.utc_now(),
      }

    %{
      server |
      queued_sessions: Map.put(server.queued_sessions, session_id, new_session)
    }
  end

  @doc """
  Take at most `limit` sessions from the waiting queue and put them in the active set.
  It returns

    {activated, new_server}

  where
    * `activated` is the number of sessions that were actually activated, and
    * `new_server` is the new state of the serer with both queues adjusted.
  """
  def activate_sessions(server, limit) when is_integer(limit) do
    sessions_by_created_at =
      server.queued_sessions
      |> Enum.into([])
      |> Enum.sort_by(fn {_id, session} -> session.created_at end)

    active_sessions =
      sessions_by_created_at
      |> Enum.take(limit)
      |> Enum.into(%{})

    queued_sessions =
      sessions_by_created_at
      |> Enum.drop(limit)
      |> Enum.into(%{})

    new_server =
      %{
        active_sessions: active_sessions,
        queued_sessions: queued_sessions,
      }

    {Enum.count(active_sessions), new_server}
  end

  @doc """
  Remove all active sessions from the server.
  """
  def terminate_active_sessions(server) do
    %{ server | active_sessions: %{} }
  end

  @doc """
  Remove a currently actie session.
  """
  def terminate_active_session(server, session_id) do
    %{ server | active_sessions: Map.delete(server.active_sessions, session_id) }
  end

  @doc """
  Remove a session from the set of sessions queued for later activation.
  """
  def terminate_queued_session(server, session_id) do
    %{ server | queued_sessions: Map.delete(server.queued_sessions, session_id) }
  end
end
