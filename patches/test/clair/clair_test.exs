defmodule Clair.HttpSuccessStub do
  @behaviour Clair.Http

  @summaries """
  {
    "Name" => "testvuln",
  }
  """

  @description """
  {
    "Name": "testvuln",
    "Link": "http://nowhe.re",
    "Severity": "High",
    "FixedIn": [
      %{
        "Name": "thatonepackage",
        "Version": "thelatestone",
      },
    ],
  }
  """

  @impl Clair.Http
  def get(url, headers \\ [], options \\ []) do
    body =
      if String.contains?(url, "limit") do
        @summaries
      else
        @description
      end

    response =
      %{
        status_code: 200,
        body: body,
      }

    {:ok, response}
  end
end

defmodule Clair.HttpFailureStub do
  @behaviour Clair.Http

  @impl Clair.Http
  def get(url, headers \\ [], options \\ []) do
    {:error, "mock failure"}
  end
end

defmodule ClairTest do
  use ExUnit.Case
  doctest Clair
end
