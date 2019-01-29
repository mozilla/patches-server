defmodule Patches.Server.Cache do
  @moduledoc """
  The cache is represented as a tree mapping platform names to a list of
  vulnerabilities affecting that platform.  Vulnerabilities are, on
  average, less than 256 bytes.  The cache defaults to storing no more
  than 8000 vulnerabilities, which would occupy about 2MB of space.

  ## Guarantees
  
  The cache guarantees that:

  1. It will never exceed an optional limit to the number of vulnerabilities
  in memory (default 8000).
  2. All iterations through a cache of vulnerabilities will be total. I.e.,
  all scanners will always get every vuln for their platform.
  """
  
  @doc """
  Create a new empty cache state.
  """
  def init(platforms) do
    for pform <- platforms,
        into: %{},
        do: {pform, []}
  end
end

defmodule Patches.Server.CacheAgent do
  @moduledoc """
  `Agent` abstraction for managing a cache.
  """

  use Agent

  alias Patches.Server.Cache

  @doc """
  Start handling a cache state storing vulnerabilities for a list of platforms.
  """
  def start_link(platforms) do
    Agent.start_link(fn -> Cache.init(platforms) end)
  end
end
