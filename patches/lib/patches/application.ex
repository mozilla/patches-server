defmodule Patches.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias Patches.Server.Agent, as: Sessions
  alias Patches.Server.Agent.Config, as: SessionsConfig
  alias Patches.StreamRegistry.Agent, as: VulnStreams
  alias Patches.StreamRegistry.Agent.Config, as: VulnStreamsConfig

  def start(_type, _args) do
    children = [
      {Plug.Cowboy, scheme: :http, plug: Patches.WebServer, options: [port: 9001]},
      {Sessions, %SessionsConfig{}},
      {VulnStreams, %VulnStreamsConfig{}},
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Patches.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
