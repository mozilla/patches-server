defmodule Patches.Server.Config do
  @moduledoc """
  A structure containing the data that a user can supply to configure the
  behaviour of a `Patches.Server`.
  """

  defstruct(
    max_active_sessions: 128,
    max_queued_sessions: 1024,
    active_session_timeout_seconds: 10 * 60,
    queued_session_timeout_seconds: 5 * 60, 
  )
end

defmodule Patches.Server.Session do
  @moduledoc """
  A structure representing a scanner session.
  """

  @enforce_keys [:platform]
  defstruct [
    :platform,
    :window_index,
    :created_at
  ]
end

defmodule Patches.Server do
  @moduledoc """
  Tracks sessions belonging to scanners requesting vulnerability information.
  """

  @doc """
  Construt a new `Patches.Server` with a given or default configuration.
  """
  def init(config \\ %Patches.Server.Config{}) do
    %{
      config: config,
      active_sessions: %{},
      queued_sessions: %{},
    }
  end

  @doc """
  Enqueue a new session for a scanner wishing to retrieve information about
  vulnerabilities affecting packages for a particular platform.

  If the server is already maintaining the maximum configured number of queued
  sessions allowed, this function returns

      {:error, :queue_full, server}

  with `server` containing the current state of the server. Otherwise, it
  returns

      {:ok, id, server}

  with `server.queued_sessions` containing a new key, `id`, corresponding to a
  new session value.
  """
  def queue_session(server, platform) when is_binary(platform) do
    if Enum.count(server.queued_sessions) < server.config.max_queued_sessions do
      new_session_id =
        generate_id(fn id -> not Map.has_key?(server.queued_sessions, id) end)

      new_session =
        %Patches.Server.Session{
          platform: platform,
          window_index: 0,
          created_at: Time.utc_now(),
        }

      new_server =
        %{
          server | queued_sessions: Map.put(
            server.queued_sessions,
            new_session_id,
            new_session)
        }

      {:ok, new_session_id, new_server}
    else
      {:error, :queue_full, server}
    end
  end

  @doc """
  Move sessions fromm the server's `queued_sessions` collection into its
  `active_sessions` collection.

  Returns

      {activated, server}

  with `activated` being the number of sessions that ended up being activated
  and `server` being the new server state.

  Defaults to activating the configured `max_active_sessions` number of
  sessions.
  """
  def activate_sessions(server) do
    activate_sessions(server, server.config.max_active_sessions)
  end

  @doc """
  See `activate_sessions/1`.
  """
  def activate_sessions(server, num) when is_integer(num) do
    currently_active =
      Enum.count(server.active_sessions)

    to_take =
      Enum.min([
        num,
        Enum.count(server.queued_sessions),
        server.config.max_active_sessions - currently_active,
      ])

    sessions_by_created_at =
      server.queued_sessions
      |> Enum.into([])
      |> Enum.sort_by(fn {_id, session} -> session.created_at end)

    active_sessions =
      sessions_by_created_at
      |> Enum.take(to_take)
      |> Enum.into(%{})
      |> Map.merge(server.active_sessions)

    queued_sessions =
      sessions_by_created_at
      |> Enum.drop(to_take)
      |> Enum.into(%{})

    new_server = %{
      server |
      active_sessions: active_sessions,
      queued_sessions: queued_sessions,
    }

    {to_take, new_server}
  end

  def terminate_active_sessions(server) do
    %{ server | active_sessions: %{} }
  end

  @doc """
  Generate a new random hex ID of a particular length. The `unqiue` argument
  must be a predicate function that, given a generated ID, returns true if the
  ID is unique or else false if it is not.
  """
  defp generate_id(length \\ 32, unique) do
    id = genid(length)
    if unique.(id) do
      id
    else
      generate_id(length, unique)
    end
  end

  @doc """
  Generate a random hex string of a particular length.
  """
  defp genid(length) do
    source = "abcdef0123456789"
    rand_chars = Enum.map(1..length, fn _n ->
      source
      |> String.length
      |> (fn n -> n - 1 end).()
      |> :rand.uniform()
      |> (fn n -> String.at(source, n) end).()
    end)
    Enum.reduce(rand_chars, "", fn char, str -> str <> char end)
  end
end
