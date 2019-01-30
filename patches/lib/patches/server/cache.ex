defmodule Patches.Server.Cache do
  @moduledoc """
  A cache is represented as a tree mapping bucket names to a list of
  corresponding values.
  """
  
  @doc """
  Create a new empty cache state.
  """
  def init(bucket_names) do
    for bucket <- bucket_names,
        into: %{},
        do: {bucket, []}
  end

  @doc """
  Register a new value in a `bucket`.
  """
  def register(cache, bucket, value) do
    Map.update(cache, bucket, [ value ], fn values -> [ value| values ] end)
  end

  @doc """
  Retrieve up to `limit` values in a `bucket`.

  The default behavior is to read all values from the provided `offset`
  or the start of the cache if no `offset` is provided.
  """
  def retrieve(cache, bucket, offset \\ 0, limit \\ nil) do
    Map.get(cache, bucket, [])
    |> Enum.drop(offset)
    |> Enum.take(limit || 0xffffff)
  end

  @doc """
  Apply a sort function to each of the lists of values cached in each bucket.
  """
  def sort_by(cache, func) do
    for key <- Map.keys(cache),
        sorted_values = Enum.sort_by(cache[key], func),
        into: %{},
        do: {key, sorted_values}
  end

  @doc """
  Apply a function to compute the desired number of values to be kept in each
  bucket.
  """
  def restrict(cache, size_fn) do
    for key <- Map.keys(cache),
        values = cache[key],
        to_keep = size_fn.(Enum.count(values)),
        into: %{},
        do: {key, Enum.take(values, to_keep)}
  end

  @doc """
  Compute a map from bucket names to their corresponding cache size.
  """
  def sizes(cache) do
    for key <- Map.keys(cache),
        into: %{},
        do: {key, Enum.count(cache[key])}
  end
end
