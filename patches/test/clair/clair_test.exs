defmodule Clair.HttpSuccessStub do
  @behaviour Clair.Http

  @summaries """
  {
    "Vulnerabilities": [
      {
        "Name": "testvuln"
      },
      {
        "Name": "testvuln2"
      }
    ],
    "NextPage": "testpage"
  }
  """

  @description """
  {
    "Name": "testvuln",
    "Link": "http://nowhe.re",
    "Severity": "High",
    "FixedIn": [
      {
        "Name": "thatonepackage",
        "Version": "thelatestone"
      }
    ]
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

defmodule Clair.HttpSucceedThenFailStub do
  @behaviour Clair.Http
  
  @summaries """
  {
    "Vulnerabilities": [
      {
        "Name": "testvuln"
      }
    ],
    "NextPage": "testpage"
  }
  """

  @impl Clair.Http
  def get(url, headers \\ [], options \\ []) do
    if String.contains?(url, "limit") do
      {:ok, %{
        status_code: 200,
        body: @summaries,
      }}
    else
      {:error, "mock failure"}
    end
  end
end

defmodule Clair.HttpInternalServerErrorStub do
  @behaviour Clair.Http

  @impl Clair.Http
  def get(url, headers \\ [], options \\ []) do
    {:ok, %{ status_code: 500 }}
  end
end

defmodule Clair.HttpInvalidJSONStub do
  @behaviour Clair.Http

  @impl Clair.Http
  def get(url, headers \\ [], options \\ []) do
    {:ok, %{ status_code: 200, body: "No server response." }}
  end
end

defmodule Clair.HttpUnexpectedDataStub do
  @behaviour Clair.Http

  @impl Clair.Http
  def get(url, headers \\ [], options \\ []) do
    body =
      "{\"notExpected\": 0}"

    {:ok, %{ status_code: 200, body: body }}
  end
end

defmodule ClairTest do
  use ExUnit.Case
  doctest Clair

  test "retrieves descriptions for all vulnerabilities served" do
    {:ok, vulns, _config} =
      Clair.init("test", "ubuntu:18.04", 32, clair.HttpSuccessStub)
      |> Clair.retrieve()

    assert Enum.count(vulns) == 2
  end

  test "returns any error it encounters making requests to clair" do
    {:error, _msg} =
      Clair.init("test", "ubuntu:18.04", 32, clair.HttpFailureStub)
      |> Clair.retrieve()
  end

  test "returns the first error it encounters" do
    {:error, _msg} =
      Clair.init("test", "ubuntu:18.04", 32, clair.HttpSucceedThenFailStub)
      |> Clair.retrieve()
  end

  test "returns an error if the server indicates a request failure" do
    {:error, _msg} =
      Clair.init("test", "ubuntu:18.04", 32, clair.HttpInternalServerErrorStub)
      |> Clair.retrieve()
  end

  test "returns an error if it doesn't receive well-formed JSON" do
    {:error, _msg} =
      Clair.init("test", "ubuntu:18.04", 32, clair.HttpInvalidJSONStub)
      |> Clair.retrieve()
  end

  test "returns an error if it doesn't receive expected data" do
    {:error, _msg} =
      Clair.init("test", "ubuntu:18.04", 32, clair.HttpUnexpectedDataStub)
      |> Clair.retrieve()
  end
end
