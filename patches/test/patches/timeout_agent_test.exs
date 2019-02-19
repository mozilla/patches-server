defmodule Patches.Timeout.AgentTest do
  use ExUnit.Case, async: true
  doctest Patches.Timeout.Agent

  alias Patches.Timeout.Agent, as: Timeouts
  alias Patches.Timeout.Agent.Config

  setup do
    config =
      %Config{
        timeout: 3,
        sleep: 1,
      }

    {:ok, pid} =
      Timeouts.start_link(config)

    %{
      config: config,
      pid: pid,
    }
  end

  test "Inactive sessions will be considered timed-out.", %{ config: config } do
    spawn &Timeouts.run/0
    Timeouts.notify_activity(session: "testid")

    :timer.sleep((config.timeout + 1) * 1000)

    assert ["testid"] == Timeouts.timed_out()
  end

  test "Active sessions will not be considered timed-out.", %{ config: config } do
    spawn &Timeouts.run/0
    Timeouts.notify_activity(session: "testid2")

    :timer.sleep((config.timeout - 1) * 1000)
    
    Timeouts.notify_activity(session: "testid2")

    :timer.sleep(2000)

    assert [] == Timeouts.timed_out()
  end
end
