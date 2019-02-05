defmodule Clair.Agent do
  @moduledoc """
  An asynchronous interface to a Clair-backed vulnerability source.
  """

  use Agent

  alias Patches.Vulnerability, as: Vuln

  @doc """
  Start a link to an `Agent` containing a `Clair` configuration.
  """
  def start_link(clair_config) do
    init =
      %{
        config: clair_config,
        state: :not_ready,
        vulns: [],
      }

    Agent.start_link(fn -> init end, name: __MODULE__)
  end

  @doc """
  Determine if the agent has prepared vulnerabilities to serve.
  """
  def has_vulns?() do
    Agent.get(__MODULE__, fn
      %{ state: :ready } ->
        true

      _ ->
        false
    end)
  end
end
