defimpl Window, for: Clair.Agent do
  def view(agent_pid, start_index, length) do
    Clair.Agent.vulnerabilities(agent_pid)
    |> Window.view(start_index, length)
  end
end

defmodule Clair.Agent do
  @moduledoc """
  An asynchronous interface to a Clair-backed vulnerability source.
  
  ## States
  
  1. `:ready` indicates that no vulnerabilities are available yet.
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
        state: :ready,
      }

    Agent.start_link(fn -> init end)
  end

  @doc """
  Determine if the agent has prepared vulnerabilities to serve.
  """
  def has_vulns?(agent_pid) when is_pid(agent_pid) do
    Agent.get(agent_pid, fn
      %{ state: {:ok, _vulns} } ->
        true

      _ ->
        false
    end)
  end

  @doc """
  Determine if the agent is in the error state.
  """
  def has_error?(agent_pid) when is_pid(agent_pid) do
    Agent.get(agent_pid, fn
      %{ state: {:error, _reason} } ->
        true

      _ ->
        false
    end)
  end

  @doc """
  Asynchronously request more vulnerabilities. Invoke a callback function with
  arity 0 once requests are complete.
  """
  def fetch(agent_pid, callback) when is_function(callback) and is_pid(agent_pid) do
    Agent.update(agent_pid, fn
      s=%{ config: state, state: :ready } ->
        case Clair.retrieve(state) do
          {:ok, vulns, new_state} ->
            callback.()
            %{ s | state: {:ok, vulns}, config: new_state }

          {:error, reason} ->
            callback.()
            %{ s | state: {:error, reason} }
        end

      state ->
        callback.()
        state
    end)
  end

  @doc """
  Retrieve a list of vulnerabilities stored by the agent.

  If the agent is not in the ok state, an empty list is returned.
  """
  def vulnerabilities(agent_pid) when is_pid(agent_pid) do
    Agent.get(agent_pid, fn
      %{ state: {:ok, vulns} } ->
        vulns

      _ ->
        []
    end)
  end

  @doc """
  Retrieve a string explaining why the agent entered the error state.

  If the agent is not in the error state, `nil` is returned.
  """
  def error(agent_pid) when is_pid(agent_pid) do
    Agent.get(agent_pid, fn
      %{ state: {:error, reason} } ->
        reason

      _ ->
        nil
    end)
  end

  @doc """
  Clear any stored vulnerabilities to prepare the agent to fetch more.

  The agent will remain in the error state if it is already in that state.
  """
  def prepare(agent_pid) when is_pid(agent_pid) do
    Agent.update(agent_pid, fn
      s=%{ state: {:ok, _vulns} } ->
        %{ s | state: :ready }

      state ->
        state
    end)
  end
end
