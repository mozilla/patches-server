defmodule Patches.ServerTest do
  use ExUnit.Case
  doctest Patches.Server

  alias Patches.Server
  alias Patches.Server.Config


  test "new sessions are queued upon creation" do
    {:ok, _id, %{ queued_sessions: queued }} =
      Server.init()
      |> Server.queue_session("ubuntu:18.04")

    assert Enum.count(queued) == 1
  end

  test "can register sessions with unique identifiers" do
    %{ queued_sessions: queued } =
      Enum.reduce(0..3, Server.init(), fn (_n, server) ->
        {:ok, _id, server} =
          Server.queue_session(server, "ubuntu:18.04")

        server
      end)

    ids =
      queued
      |> Map.keys()
      |> Enum.uniq()

    assert Enum.count(ids) == Enum.count(queued)
  end

  test "cannot create more than a maximum number of queued sessions" do
    config =
      %Config{ max_queued_sessions: 1 }

    with server <- Server.init(config),
         {:ok, _id, server} <- Server.queue_session(server, "ubuntu:18.04"),
         {:error, :queue_full, server} <- Server.queue_session(server, "ubuntu:18.04") do
      assert Enum.count(server.queued_sessions) == 1
    end
  end

  test "can replace active sessions with queued sessions" do
    {activated, server} =
      Enum.reduce(0..2, Server.init(), fn (_n, server) ->
        {:ok, _id, server} =
          Server.queue_session(server, "ubuntu:18.04")

        server
      end)
      |> Server.activate_sessions(1)

    assert activated == 1
    assert Enum.count(server.active_sessions) == 1
    assert Enum.count(server.queued_sessions) == 2
  end

  test "up to a configured number of sessions can be made active at a time" do
    config =
      %Patches.Server.Config{ max_active_sessions: 1 }

    {activated, server} =
      Enum.reduce(0..2, Server.init(config), fn (_n, server) ->
        {:ok, _id, server} =
          Server.queue_session(server, "ubuntu:18.04")

        server
      end)
      |> Server.activate_sessions(3)

    assert activated == 1
    assert Enum.count(server.active_sessions) == 1
    assert Enum.count(server.queued_sessions) == 2
  end

  test "the most recently created sessions are activated first" do
    {_activated, server} =
      Enum.reduce(0..2, Server.init(), fn (_n, server) ->
        {:ok, _id, server} =
          Server.queue_session(server, "ubuntu:18.04")

        server
      end)
      |> Server.activate_sessions(1)

    [ activated | _rest ] =
      server.active_sessions
      |> Enum.map(fn {_id, session} -> session end)

    [ queued1 | [ queued2 | _rest ]] =
      server.queued_sessions
      |> Enum.map(fn {_id, session} -> session end)

    assert activated.created_at < queued1.created_at
    assert activated.created_at < queued2.created_at
  end
end
