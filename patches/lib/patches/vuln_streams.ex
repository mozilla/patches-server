defmodule Patches.VulnStreams do
  @moduledoc false

  use GenServer

  alias Patches.StreamFn
  alias Patches.VulnFn

  # Client

  def start_link([]) do
    start_link(["http://127.0.0.1:6060"])
  end

  def start_link([base_addr | _]) do
    state = %{
      base_address: base_addr,
      streams: %{}
    }
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def fetch(platform), do: GenServer.cast(__MODULE__, {:fetch, platform})
  def retrieve(id), do: GenServer.call(__MODULE__, {:retrieve, id})

  # Server
  
  def init(state), do: {:ok, state}

  def handle_call({:retrieve, id}, _from, state) do
    if Map.has_key?(state.streams, id) do
      drain_stream(state, id)
    else
      {:reply, {:error, :invalid_id}, state}
    end
  end

  def handle_cast({:fetch, platform}, state) when is_binary(platform) do
    gen_id = fn -> generate_id(fn id -> not Map.has_key?(state.streams, id) end) end
    new_state = case vuln_summaries(state.base_address, platform, gen_id) do
      {:ok, id, vulns, next_page} ->
        new_stream = StreamFn.stream(vulns, next_page)
        %{state | streams: Map.put(state.streams, id, new_stream)}

      {:error, id, reason} ->
        new_stream = StreamFn.stream(:error, reason)
        %{state | streams: Map.put(state.streams, id, new_stream)}
    end
      
    {:noreply, new_state}
  end

  def handle_cast({:describe, id, stream}, state) do
    {:noreply, state}
  end

  def handle_cast({:stream_step, id, stream}, state) do
    new_state = cond do
      StreamFn.is_done?(stream) ->
        %{state | streams: Map.delete(state.streams, id)}

      true ->
        state
    end

    {:noreply, new_state}
  end

  defp vuln_summaries(base_addr, platform, gen_id) do
    url = "#{base_addr}/v1/namespaces/#{platform}/vulnerabilities?limit=50"
    id = gen_id.()
    case HTTPoison.get(url) do
      {:ok, response} ->
        json = Poison.decode!(response.body)
        vulns = Map.get(json, "Vulnerabilities", [])
        next_page = Map.get(json, "NextPage", "")
        {:ok, id, vulns, next_page}

      {:error, %HTTPoison.Error{ reason: reason }} ->
        {:error, id, reason}
    end
  end

  defp vuln_description(base_addr, platform, vuln_summary) do
    url = "#{base_addr}/v1/#{platform}/vulnerabilities/#{vuln_summary["Name"]}?fixedIn"
    case HTTPoison.get(url) do
      {:ok, response} ->
        vuln = response.body
          |> Poison.decode!()
          |> Map.get("Vulnerability")
          |> VulnFn.from_json(platform)
        {:ok, vuln}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end

  defp drain_stream(state, id) do
    case StreamFn.drain(state.streams[id]) do
      {:ok, vulns, new_stream} ->
        GenServer.cast(__MODULE__, {:stream_step, id, new_stream})
        new_state = %{state | streams: Map.put(state.streams, id, new_stream)}
        {:reply, {:ok, vulns}, new_state}

      {:error, reason, _stream} ->
        {:reply, {:error, reason}, state}
    end
  end

  defp generate_id(id \\ 1, unique) do
    if unique.(id) do
      id
    else
      generate_id(id + 1, unique)
    end
  end
end
