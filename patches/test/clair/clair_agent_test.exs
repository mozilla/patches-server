defmodule Clair.AgentTest do
  use ExUnit.Case, async: true
  doctest Clair.Agent

  setup do
    config =
      Clair.init("http://127.0.0.1:6060", "ubuntu:18.04", 32, Clair.HttpSuccessStub)

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

  test "vulnerabilities can be fetched asynchronously" do
    me =
      self()

    Clair.Agent.fetch(fn -> send(me, :ready) end)

    receive do
      :ready ->
        assert Clair.Agent.has_vulns?()

      _ ->
        assert false
    end

    assert Enum.count(Clair.Agent.vulnerabilities()) == 2
  end

  test "no vulnerabilities present before fetching" do
    assert Enum.count(Clair.Agent.vulnerabilities()) == 0
  end
end
