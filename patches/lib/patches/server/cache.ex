defmodule Patches.Server.Cache do
  @moduledoc """
  The cache is represented as a tree mapping platform names to a list of
  vulnerabilities affecting that platform.
  """
  
  @doc """
  Create a new empty cache state.
  """
  def init(platforms) do
    for pform <- platforms,
        into: %{},
        do: {pform, []}
  end

  @doc """
  Register a new vulnerability affecting a supported platform to the cache.
  """
  def register(cache, platform, vuln) do
    Map.update(cache, platform, [ vuln ], fn vulns -> [ vuln | vulns ] end)
  end

  @doc """
  Retrieve up to `limit` vulnerabilities affecting `platform` from an `offset`.

  The default behavior is to read all vulnerabilities from the provided offset
  or the start of the cache if no offset is provided.
  """
  def retrieve(cache, platform, offset \\ 0, limit \\ nil) do
    Map.get(cache, platform, [])
    |> Enum.drop(offset)
    |> Enum.take(limit || 0xffffff)
  end

  @doc """
  Apply a sort function to each of the lists of vulnerabilities cached for each
  supported platform.
  """
  def sort_by(cache, func) do
    for key <- Map.keys(cache),
        sorted_vulns = Enum.sort_by(cache[key], func),
        into: %{},
        do: {key, sorted_vulns}
  end

  @doc """
  Apply a function to compute the desired number of vulnerabilities to be kept
  in the cache corresponding to each platform.
  """
  def restrict(cache, size_fn) do
    for key <- Map.keys(cache),
        vulns = cache[key],
        to_keep = size_fn.(Enum.count(vulns)),
        into: %{},
        do: {key, Enum.take(vulns, to_keep)}
  end

  @doc """
  Compute a map from supported platforms to their corresponding cache size.
  """
  def sizes(cache) do
    for key <- Map.keys(cache),
        into: %{},
        do: {key, Enum.count(cache[key])}
  end
end
