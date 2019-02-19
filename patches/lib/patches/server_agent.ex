defmodule Patches.Server.Agent.Config do
  @moduledoc """
  A structure containing the data that a user can supply to configure the
  behaviour of a `Patches.Server.Agent`.

  * max_active_sessions: A maximum number of sessions to activate and serve
  vulnerabilities to at a time.
  * max_queued_sessions: A maximum number of sessions to queue for actiation.
  * active_session_timeout_seconds: The maximum number of seconds to allow to
  pass without hearing from an active session before considering it to have
  timed out and be removed.
  * queued_session_timeout_seconds: The maximum number of seconds to allow to
  pass without hearing from a queued session before considering it to have
  timed out and be removed.
  * max_vuln_cache_size: A maximum number of vulnerabilities to allow to be
  cached in memory, per platform.
  """

  defstruct(
    max_active_sessions: 128,
    max_queued_sessions: 1024
  )
end

defmodule Patches.Server.Agent do
  @moduledoc """
  An agent with the responsibility of maintaining the state of active and
  queued sessions waiting to be handled.  It has an implicit dependency on the
  `Patches.StreamRegistry.Agent`.
  """

  use Agent

  alias Patches.Server
  alias Patches.Server.Agent.Config

  def start_link(config \\ %Config{})

  @doc """
  Start and link a new server agent configured to apply constraints to the state.
  """
  def start_link(config) do
    init =
      %{
        config: config,
        state: Patches.Server.init(),
      }

    Agent.start_link(fn -> init end, name: __MODULE__)
  end

  @doc """
  Enqueue a new session for a scanner wishing to retrieve vulns for a specific platform.

  Returns

      {:ok, session_id}

  if there is room in the queue, where `session_id` is the identifier generated for the
  new session. If there is not room in the queue, then

      {:error, :queue_full}

  is returned instead.
  """
  def queue_session(scanning: platform) when is_binary(platform) do
    Agent.get_and_update(__MODULE__, fn %{ state: state, config: config } ->
      new_session_id =
        generate_id(fn id -> not Map.has_key?(state.queued_sessions, id) end)

      {to_caller, new_state} =
        if Enum.count(state.queued_sessions) <= config.max_queued_sessions do
          {
            {:ok, new_session_id},
            Server.queue_session(state, platform, new_session_id),
          }
        else
          {
            {:error, :queue_full},
            state,
          }
        end

      {to_caller, %{ state: new_state, config: config }}
    end)
  end

  @doc """
  Activate up to a configured number of queued sessions, replacing any that were
  active at the time of calling.

  Returns the number of sessions that were activated.
  """
  def activate_sessions() do
    Agent.get_and_update(__MODULE__, fn %{ state: state, config: config } ->
      limit =
        Enum.min([
          config.max_active_sessions,
          Enum.count(state.queued_sessions),
        ])

      {activated, new_state} =
        Server.activate_sessions(state, limit)
      
      {activated, %{ state: new_state, config: config }}
    end)
  end

  @doc """
  Retrieve a list of all sessions currently active.
  """
  def active() do
    Agent.get(__MODULE__, fn %{ state: %{ active_sessions: a } } ->
      a
      |> Enum.into([])
      |> Enum.map(fn {_id, session} -> session end)
    end)
  end

  @doc """
  Retrieve a list of all sessions currently queued.
  """
  def queued() do
    Agent.get(__MODULE__, fn %{ state: %{ queued_sessions: q } } ->
      q
      |> Enum.into([])
      |> Enum.map(fn {_id, session} -> session end)
    end)
  end

  @doc """
  Remove a session from the active & queued sets.
  """
  def terminate_session(session_id) when is_binary(session_id) do
    Agent.update(__MODULE__, fn %{ state: state, config: config } ->
      new_state =
        state
        |> Server.terminate_active_session(session_id)
        |> Server.terminate_queued_session(session_id)

      %{
        config: config,
        state: new_state,
      }
    end)
  end
  
  @doc """
  Generate a new random hex ID of a particular `length`.

  ## Arguments

    1 (optional) The number of bytes of hex to generate. Defaults to `32`.
    2. The `unqiue` argument must be a predicate function that, given a
    generated ID, returns true if the ID is unique or else false.

  ## Returns

  A hex string of the specified `length`.
  """
  def generate_id(length \\ 32, unique) when is_function(unique) do
    id =
      1..length
      |> Enum.map(fn _n -> String.at("abcdef0123456789", :rand.uniform(15)) end)
      |> Enum.reduce("", fn (char, str) -> str <> char end)

    if unique.(id) do
      id
    else
      generate_id(length, unique)
    end
  end
end
