defmodule Patches.ServerTest do
  use ExUnit.Case
  doctest Patches.Server

  alias Patches.Server
  alias Patches.Server.Config


  test "new sessions are queued upon creation" do
    {:ok, %{ queued_sessions: queued }} =
      Server.init()
      |> Server.queue_session("ubuntu:18.04")

    assert Enum.count(queued) == 1
  end

  test "can register sessions with unique identifiers" do
    %{ queued_sessions: queued } =
      Enum.reduce(0..3, Server.init(), fn (_n, server) ->
        {:ok, server} = Server.queue_session("ubuntu:18.04")
        server
      end)

    ids =
      Enum.map(queued, fn q -> q.id end)
      |> Enum.uniq()

    assert Enum.count(ids) == Enum.count(queued)
  end

  test "cannot create more than a maximum number of queued sessions" do
    config =
      %Config{ max_queued_sessions: 1 }

    with server <- Server.init(config),
         {:ok, server} <- Server.queue_session("ubuntu:18.04"),
         {:error, :queue_full, server} <- Server.queue_session("ubuntu:18.04") do
      assert Enum.count(server.queued_sessions) == 1
    end
  end
end
