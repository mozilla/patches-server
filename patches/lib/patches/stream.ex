defmodule Patches.Stream do
  @moduledoc """
  The state of a stream of vulnerabilities from Clair.
  """

  defstruct state: :not_started, vulns: [], next_page: ""
end

defmodule Patches.StreamFn do
  @moduledoc """
  Functions for manipulating streams of vulnerabilities.
  """

  alias Patches.Stream
end
