defmodule Patches do
  @moduledoc """
  Manages the state of the `Patches.Server.Agent` and `Patches.StreamRegistry.Agent`.

  In particular, `Patches`:

  1. Checks active and queued sessions periodically to determine if they have timed out.
  2. Removes timed-out sessions.
  3. Updates vulnerability sources.
  """

  use Agent

  @doc """
  """
  def start_link(timeout_seconds \\ 30, sleep_seconds \\ 5) do
    init =
      %{
        timeout: timeout_seconds,
        state: :not_started,
        config: %{
          timeout: timeout_seconds,
          sleep: sleep_seconds * 1000,
        },
        sessions: %{},
      }

    Agent.start_link(fn -> init end, name: __MODULE__)
  end

  def manage_session_timeouts() do
    Agent.update(__MODULE__, fn state ->
      running? =
        state.state != :stopped
        
      if running? do
        timed_out =
          state.sessions
          |> Enum.into([])
          |> Enum.filter(fn {id, _session} -> timed_out?(id) end)
        
        new_sessions =
          state.sessions
          |> Enum.into([])
          |> Enum.filter(fn {id, _session} -> Enum.find(timed_out, &( id == &1 )) == nil end)

        new_state =
          %{ state | sessions: new_sessions }

        Enum.each(timed_out, fn session_id ->
          RegistryAgent.terminate_session(session_id)
          ServerAgent.terminate_session(session_id)
        end)

        new_state
      else
        state
      end
    end)
      
    :timer.sleep(state.config.sleep)
    manage_session_timeouts
  end

  def stop() do
    Agent.update(__MODULE__, &Map.put(&1, :state, :stopped))
  end

  def notify_activity(session: session_id) when is_binary(session_id) do
    Agent.get_and_update(__MODULE__, fn log=%{ sessions: %{ ^session_id => last_heard_from } } ->
      new_state =
        %{ log | sessions: Map.put(log.sessions, session_id, Time.utc_now()) }

      {last_heard_from, new_state}
    end)
  end

  def timed_out?(session_id) when is_binary(session_id) do
    Agent.get(__MODULE__, fn %{ timeout: t_s, sessions: %{ ^session_id => last_heard_from } } ->
      timed_out =
        last_heard_from
        |> Time.add(t_s)
        |> Time.compare(Time.utc_now())

      case timed_out do
        :eq ->
          true

        :lt ->
          true

        :gt ->
          false
      end
    end)
  end

  defp remove(session_id) when is_binanry(session_id) do
    Agent.update(__MODULE__, fn state ->
      %{ state | sessions: Map.delete(state.sessions, session_id) }
    end)
  end
end
