defmodule Patches.StreamRegistry.SessionState do
  @moduledoc """
  Representation of the state of a scanner session being managed by a
  `Patches.StreamManager`.
  """

  defstruct [
    :platform,
    :window_index,
    :last_read_at,
  ]
end

defmodule Patches.StreamRegistry do
  @moduledoc """
  A data structure representing the state of a registry system tracking
  the states of streams for scanners with active sessions.

  ## Representation

  ```elixir
  %{
    caches: %{
      "platform 1" => CacheWindow,
      "platform 2" => CacheWindow,
    },
    sessions: %{
      "session id 1" => SessionState,
      "session id 2" => SessionState,
    }
  }
  ```
  """

  @doc """
  Initialize an empty registry.
  """
  def init() do
    %{
      caches: %{},
      sessions: %{},
    }
  end
end
