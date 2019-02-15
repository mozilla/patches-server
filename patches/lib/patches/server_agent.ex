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
    max_queued_sessions: 1024,
    active_session_timeout_seconds: 10 * 60,
    queued_session_timeout_seconds: 5 * 60,
    max_vuln_cache_size: 1024,
  )
end

defmodule Patches.Server.Agent do
  @moduledoc """
  An agent that manages a `Patches.Server` state.
  """

  use Agent

  @doc """
  Start and link a new server agent configured to apply constraints to the state.
  """
  def start_link(config) do
    init =
      %{
        config: config,
        state: Patches.Server.init(),
      }

    Agent.start_link(fn -> init end)
  end
end
