defmodule Patches.StreamRegistry.AgentTest do
  use ExUnit.Case, async: true
  doctest Patches.StreamRegistry.Agent

  alias Patches.StreamRegistry.Agent, as: SRAgent
  alias Patches.StreamRegistry.Agent.Config

  setup do
    config =
      %Config{
        max_window_length: 10,
        lookup_limit: 10,
      }

    {:ok, pid} =
      SRAgent.start_link(config, Registry.init())

    %{
      config: config,
      pid: pid,
    }
  end
end
