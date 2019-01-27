defmodule Patches.VulnStreams do
  @moduledoc false

  use GenServer

  alias Patches.StreamFn

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
    IO.puts "Fetching vulns"
    url = "#{state.base_address}/v1/namespaces/#{platform}/vulnerabilities?limit=50"
    id = generate_id(fn id -> not Map.has_key?(state.streams, id) end)
    new_state = case HTTPoison.get(url) do
      {:ok, response} ->
        json = Poison.decode! response.body
        vulns = Map.get(json, "Vulnerabilities", [])
        next_page = Map.get(json, "NextPage", "")
        IO.puts "Got vulns"
        IO.inspect vulns
        IO.puts "Got next page #{next_page}"
        new_stream = StreamFn.stream(vulns, next_page)
        %{state | streams: Map.put(state.streams, id, new_stream)}

      {:error, %HTTPoison.Error{reason: reason}} ->
        IO.puts "Got an error from Clair"
        new_stream = StreamFn.stream(:error, reason)
        %{state | streams: Map.put(state.streams, id, new_stream)}
    end

    {:noreply, new_state}
  end

  def handle_cast({:stream_step, id, stream}, state) do
    new_state = if StreamFn.is_done?(stream) do
      %{state | streams: Map.delete(state.streams, id)}
    else
      state
    end

    {:noreply, new_state}
  end

  defp drain_stream(state, id) do
    IO.puts "Draining stream"
    case StreamFn.drain(state.streams[id]) do
      {:ok, vulns, new_stream} ->
        IO.puts "Retrieving vulns"
        IO.inspect vulns
        GenServer.cast(__MODULE__, {:stream_step, id, new_stream})
        new_state = %{state | streams: Map.put(state.streams, id, new_stream)}
        {:reply, {:ok, vulns}, new_state}

      {:error, reason, _stream} ->
        IO.puts "Stream in error state"
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
