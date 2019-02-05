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

  test "asserts that no vulns are loaded upon initialization", %{ pid: pid } do
    assert not Clair.Agent.has_vulns?(pid)
  end

  test "vulnerabilities can be fetched asynchronously", %{ pid: pid } do
    me =
      self()

    Clair.Agent.fetch(pid, fn -> send(me, :ready) end)

    receive do
      :ready ->
        assert Clair.Agent.has_vulns?(pid)

      _ ->
        assert false
    end

    assert Enum.count(Clair.Agent.vulnerabilities(pid)) == 2
  end

  test "no vulnerabilities present before fetching", %{ pid: pid } do
    assert Enum.count(Clair.Agent.vulnerabilities(pid)) == 0
  end
end
