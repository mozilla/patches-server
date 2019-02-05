defmodule Clair.Agent do
  @moduledoc """
  An asynchronous interface to a Clair-backed vulnerability source.
  
  ## States
  
  1. `:not_ready` indicates that no vulnerabilities are available yet.
  2. `{:error, reason}` indicates that an error has been encountered.
  3. `{:ok, vulns}` indicates that vulnerabilities are available.

  ```
                  
    ,---,  a   ,---, .---, 
    | 1 | ---> | 2 |<    |d
    '---'      '---' '---'
     /  ^
   b|   |c
    v  /
    ,---,
    | 3 |
    '---'
  ```

  * Transition `a` occurs when an error is encounterd tring to fetch vulns.
  * Transition `b` occurs when vulns are fetched successfully.
  * Transition `c` occurs when vulns are retrieved from the agent.
  * Transition `d` occurs to keep the agent in the error state once entered.
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
      }

    Agent.start_link(fn -> init end, name: __MODULE__)
  end

  @doc """
  Determine if the agent has prepared vulnerabilities to serve.
  """
  def has_vulns?() do
    Agent.get(__MODULE__, fn
      %{ state: {:ok, _vulns} } ->
        true

      _ ->
        false
    end)
  end
end
