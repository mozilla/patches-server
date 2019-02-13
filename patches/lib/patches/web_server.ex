defmodule Patches.WebServer do
  import Plug.Conn

  def init(options), do: options

  def call(conn, options), do: serve_vulnerabilities(conn, options)

  defp serve_vulnerabilities(conn, options) do
    send_resp(conn, 200, "Hello, World")
  end
end
