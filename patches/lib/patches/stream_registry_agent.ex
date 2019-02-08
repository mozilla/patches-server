defmodule Patches.StreamRegistry.Agent.Config do
  @moduledoc """
  A struct type providing named fields for configuration parameters
  that we would like to supply as defaults to the `Agent`.

  * `max_window_length` defines the maximum number of vulnerabilities
  each `CacheWindow` will be allowed to hold.
  * `lookup_limit` defines the maximum number of vulnerabilities to
  retrieve with each `cache_lookup`.
  """

  defstruct(
    max_window_length: 8000,
    lookup_limit: 128,
  )
end

defmodule Patches.StreamRegistry.Agent do
  @moduledoc """
  """

  use Agent

  @doc """
  Start a link to an `Agent` maintaining a given `StreamRegistry`.
  """
  def start_link(config, stream_registry) do
    init =
      %{
        config: config,
        registry: stream_registry,
      }

    Agent.start_link(fn -> init end, name: __MODULE__)
  end
end
