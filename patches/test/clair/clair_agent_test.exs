defmodule Clair.AgentTest do
  use ExUnit.Case, async: true
  doctest Clair.Agent

  setup do
    config =
      Clair.init("http://127.0.0.1:6060", "ubuntu:18.04", 32)

    {:ok, pid} =
      Clair.Agent.start_link(config)

    %{
      config: config,
      pid: pid,
    }
  end

  test "asserts that no vulns are loaded upon initialization" do
    assert not Clair.Agent.has_vulns?()
  end
end
