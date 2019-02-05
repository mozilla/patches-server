defmodule Clair.Http do
  @moduledoc """
  A behaviour to abstract an HTTP request, intended to facilitate unit testing.
  """

  @typep url :: binary()
  @typep headers :: [{atom, binary}] | [{binary, binary}] | %{binary => binary}
  @typep options :: Keyword.t()

  @type success :: {:ok, map()} | map()
  @type failure :: {:error, binary()}

  @callback get(url, headers \\ [], options \\ []) :: success | failure
end

defmodule Clair do
  @moduledoc """
  """

  alias Patches.Vulnerability.Source

  @behaviour Source

  @impl Source
  def retrieve(state) do
    {:error, :not_implemented}
  end
  
  def init(http_client \\ HTTPoison, base_url, platform, vulns_per_request) do
    %{
      http: http_client,
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
end
