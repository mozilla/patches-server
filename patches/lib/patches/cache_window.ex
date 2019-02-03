defprotocol Window do
  @doc """
  Open a view over a collection of data from a start position to an end position.
  """
  def view(collection, start_index, length)
end

defmodule Patches.CacheWindow do
  @moduledoc """
  """
end

defimpl Window, for: List do
  def view(collection, start_index, length) do
    collection
    |> Enum.drop(start_index)
    |> Enum.take(length - start_index + 1)
  end
end
