defmodule Patches.Server.CacheAgent do
  @moduledoc """
  `Agent` abstraction for managing a cache.

  Vulnerabilities are, on average, less than 256 bytes.  The cache defaults
  to storing no more than 8000 vulnerabilities, which would occupy about
  2MB of space.

  ## Guarantees
  
  The cache guarantees that:

  1. It will never exceed an optional limit to the number of vulnerabilities
  in memory (default 8000).
  2. All iterations through a cache of vulnerabilities will be total. I.e.,
  all scanners will always get every vuln for their platform.
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
