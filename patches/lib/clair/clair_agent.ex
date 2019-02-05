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
    Agent.start_link(fn -> clair_config end, name: __MODULE__)
  end
end
