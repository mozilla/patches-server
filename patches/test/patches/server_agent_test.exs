defmodule Patches.Server.AgentTest do
  use ExUnit.Case, async: true
  doctest Patches.Server.Agent

  alias Patches.Server.Agent, as: ServerAgent
  alias Patches.Server.Agent.Config, as: AgentConfig

  setup do
    config =
      %AgentConfig{
        max_active_sessions: 1,
        max_queued_sessions: 2,
      }

    {:ok, pid} =
      ServerAgent.start_link(config)

    %{
      config: config,
      server: pid,
    }
  end

  test "enforces a limit on the number of sessions to queue" do
    {:ok, _id} =
      ServerAgent.queue_session(scanning: "ubuntu:18.04")

    {:ok, _id} =
      ServerAgent.queue_session(scanning: "alpine:3.4")
    
    {:ok, _id} =
      ServerAgent.queue_session(scanning: "debian:unstable")

    {:error, :queue_full} =
      ServerAgent.queue_session(scanning: "ubuntu:18.04")
  end

  test "enforces a limit on the number of sessions to activate" do
    {:ok, _id} =
      ServerAgent.queue_session(scanning: "ubuntu:18.04")

    {:ok, _id} =
      ServerAgent.queue_session(scanning: "alpine:3.4")

    activated =
      ServerAgent.activate_sessions()

    assert activated == 1
  end
end
