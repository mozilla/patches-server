defprotocol Window do
  @doc """
  Open a view over a collection of data from a start position to an end position.
  """
  def view(collection, start_index, length)
end

defimpl Window, for: List do
  def view(collection, start_index, length) do
    collection
    |> Enum.drop(start_index)
    |> Enum.take(length - start_index)
  end
end

defmodule Patches.CacheWindow do
  @moduledoc """
  Mantains a view over a collection.
  """

  @doc """
  Initialize a representation of a sliding window over a collection.

  The collection must implement the `Window` protocol.
  """
  def init(collection, start_size) when is_integer(start_size) do
    %{
      collection: collection,
      view: Window.view(collection, 0, start_size),
      start_index: 0,
      length: start_size,
    }
  end

  @doc """
  Apply a function to update the underlying collection being managed.
  """
  def update(cache, update_fn) when is_function(update_fn) do
    %{ cache | collection: update_fn.(cache.collection) }
  end
end
