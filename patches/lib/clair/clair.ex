defmodule Clair.Http do
  @moduledoc """
  A behaviour to abstract an HTTP request, intended to facilitate unit testing.
  """

  @typep url :: binary()
  @typep headers :: [{atom, binary}] | [{binary, binary}] | %{binary => binary}
  @typep options :: Keyword.t()

  @type success :: {:ok, map()} | map()
  @type failure :: {:error, binary()}

  @callback get(url, headers, options) :: success | failure
end

defmodule HTTP do
  @behaviour Clair.Http

  @impl Clair.Http
  def get(url, headers \\ [], options \\ []) do
    HTTPoison.get(url, headers, options)
  end
end

defmodule Clair do
  @moduledoc """
  A client for the Clair vulnerability database's API.

  !! **Warning** !!

  Calls to `retrieve` involve making multiple blocking HTTP requests.
  """

  alias Patches.Vulnerability.Source

  @behaviour Source

  @impl Source
  def retrieve(state) do
    summaries_and_next_page =
      fn
        %{ "Vulnerabilities" => v, "NextPage" => p } ->
          [v, p]

        %{ "Error" => err } ->
          {:error, err}

        _ ->
          {:error, "Missing expected data"}
      end
    
    collapse_results =
      fn
        ({:ok, value}, {:ok, values}) ->
          {:ok, [ value | values ]}

        ({:error, err}, {:ok, _values}) ->
          {:error, err}

        (_result, {:error, err}) ->
          {:error, err}
      end


    all_descriptions =
      fn sums ->
        sums
        |> Enum.map(fn summary -> description(state, summary["Name"]) end)
        |> Enum.reduce({:ok, []}, collapse_results)
      end

    with {:ok, json} <- summaries(state),
         [sums, np] when is_binary(np) <- summaries_and_next_page.(json),
         {:ok, vulns} <- all_descriptions.(sums)
    do
      {:ok, vulns, %{ state | next_page: np }}
    end
  end

  @doc """
  Initialize a configuraion for the Clair vulnerability source.

  ## Arguments:
  
  1. A URL for a server hosting the Clair API at "/", such as
  `"http://127.0.0.1:6060"`
  2. The name of a supported platform, such as `"ubuntu:18.04"`.
  3. (default 32) A maximum number of vulnerabilities to fetch per request.
  4. (default HTTP) - An implementation of the `Clair.Http` behaviour.
  """
  def init(base_url, platform, vulns_per_request \\ 32, http \\ HTTP) do
    %{
      http: http,
      base_url: base_url,
      platform: platform,
      to_fetch: vulns_per_request,
      next_page: "",
    }
  end

  defp summary_url(%{
    base_url: base,
    platform: pform,
    to_fetch: limit,
    next_page: page,
  }) when page == "" do
    "#{base}/v1/namespaces/#{pform}/vulnerabilities?limit=#{limit}"
  end
  
  defp summary_url(%{
    base_url: base,
    platform: pform,
    to_fetch: limit,
    next_page: page,
  }) do
    "#{base}/v1/namespaces/#{pform}/vulnerabilities?page=#{page}&limit=#{limit}"
  end

  defp description_url(%{ base_url: base, platform: pform }, vuln_name) do
    "#{base}/v1/namespaces/#{pform}/vulnerabilities/#{vuln_name}?fixedIn"
  end

  defp summaries(config = %{ http: client }) do
    config
    |> summary_url()
    |> client.get()
    |> try_decode_json()
  end

  defp description(config = %{ http: client }, vuln_name) do
    config
    |> description_url(vuln_name)
    |> client.get()
    |> try_decode_json()
  end

  defp try_decode_json({:ok, %{ body: body }}) do
    try do
      {:ok, Poison.decode!(body)}
    rescue
      Poison.ParseError ->
        {:error, "JSON decode error"}

      Poison.DecodeError ->
        {:error, "JSON decode error"}
    end
  end

  defp try_decode_json({:ok, %{ status_code: 500 }}) do
    {:error, "Internal server error"}
  end

  defp try_decode_json({:error, reason}) do
    {:error, reason}
  end
end
