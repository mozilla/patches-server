defmodule Patches.VulnStreams do
  @moduledoc false

  use GenServer

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
    case state.streams[id] do
      {:ok, vulns, next_page} ->
        GenServer.cast(__MODULE__, {:fetch_more, id, next_page})
        new_state = %{state | streams: Map.put(state.streams, id, {:ok, [], next_page})}
        {:reply, {:ok, vulns}, new_state}

      {:done, vulns, _} ->
        streams = Map.delete(state.streams, id)
        new_state = %{state | streams: streams}
        {:reply, {:ok, vulns}, new_state}

      {:error, reason} ->
        {:reply, {:error, reason}, state}

      nil ->
        {:reply, {:error, :invalid_id}, state}
    end
  end

  def handle_cast({:fetch, platform}, state) when is_binary(platform) do
    url = "#{state.base_address}/v1/namespaces/#{platform}/vulnerabilities?limit=50"
    id = generate_id(fn id -> not Map.has_key?(state.streams, id) end)
    new_state = case HTTPoison.get(url) do
      {:ok, response} ->
        json = Poison.decode! response.body
        vulns = Map.get(json, "Vulnerabilities", [])
        next_page = Map.get(json, "NextPage", "")
        status = if next_page == "" do
          :done
        else
          :ok
        end
        new_stream = {status, vulns, next_page}
        %{state | streams: Map.put(state.streams, id, new_stream)}

      {:error, %HTTPoison.Error{reason: reason}} ->
        %{state | streams: Map.put(state.streams, id, {:error, reason})}
    end

    {:noreply, new_state}
  end

  def handle_cast({:fetch_more, _id, _next_page}, state) do
    {:noreply, state}
  end

  defp generate_id(id \\ 1, unique) do
    if unique.(id) do
      id
    else
      generate_id(id + 1, unique)
    end
  end
end
