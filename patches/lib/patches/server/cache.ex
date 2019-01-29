defmodule Patches.Server.Cache do
  @moduledoc """
  An `Agent` abstraction for a cache containing information about
  vulnerabilities affecting particular platforms.

  ## Representation
  
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
end
