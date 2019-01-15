defmodule Patches.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      Patches.VulnStreams
    ]

    opts = [strategy: :one_for_one, name: Patches.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
