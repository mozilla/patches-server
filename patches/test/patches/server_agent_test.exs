defmodule Patches.Server.AgentTest do
  use ExUnit.Case, async: true
  doctest Patches.Server.Agent

  alias Patches.Server.Agent.Config, as: AgentConfig

  setup do
    config =
      %AgentConfig{
        max_active_sessions: 3,
        max_queued_sessions: 5,
        active_session_timeout_seconds: 3,
        queued_session_timeout_seconds: 10,
        max_vuln_cache_size: 3,
      }

    {:ok, pid} =
      Patches.Server.Agent.start_link()

    %{
      config: config,
      pii: pid,
    }
  end
end
