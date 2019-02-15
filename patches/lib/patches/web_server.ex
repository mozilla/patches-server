defmodule Patches.WebServer do
  import Plug.Conn

  @missing_params_msg "Request missing required query string parameters platform/requestID" 

  def init(options), do: options

  def call(conn, options), do: handle(conn, options)

  defp handle(conn, options) do
    query =
      conn
      |> Map.get(:query_string)
      |> Plug.Conn.Query.decode()
   
    case query do
      %{ "requestID" => req_id } ->
        serve_vulnerabilities(conn, req_id)

      %{ "platform" => platform } ->
        register_session(conn, platform)

      _ ->
        error(conn)
    end
    
    send_resp(conn, 200, "Hello, World")
  end

  defp serve_vulnerabilities(conn, req_id) do
  end

  defp register_session(conn, platform) do
  end

  defp error(conn) do
    error =
      Poison.encode(%{ "Error" => @missing_params_msg })

    send_resp(conn, 400, error)
  end
end
