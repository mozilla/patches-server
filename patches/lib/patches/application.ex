defmodule Patches.Application do
  @moduledoc false

  use Application

  alias Patches.Timeout.Agent, as: Timeouts
  alias Patches.Timeout.Agent.Config, as: TimeoutsConfig
  alias Patches.Server.Agent, as: Sessions
  alias Patches.Server.Agent.Config, as: SessionsConfig
  alias Patches.StreamRegistry.Agent, as: VulnStreams
  alias Patches.StreamRegistry.Agent.Config, as: VulnStreamsConfig

  def start(_type, _args) do
    children =
      [
        {Plug.Cowboy, scheme: :http, plug: Patches.WebServer, options: [port: 9001]},
        {Sessions, %SessionsConfig{}},
        {VulnStreams, %VulnStreamsConfig{}},
        {Timeouts, %TimeoutsConfig{}},
      ]

    opts =
      [strategy: :one_for_one, name: Patches.Supervisor]

    resp =
      Supervisor.start_link(children, opts)

    Timeouts.run()

    resp
  end
end
