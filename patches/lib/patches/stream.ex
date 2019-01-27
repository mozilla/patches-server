defmodule Patches.Stream do
  @moduledoc """
  The state of a stream of vulnerabilities from Clair.

  Preparing information about vulnerabilities affecting a platform requires making
  a number of calls to Clair.

  1. Request a list of summaries of information about vulnerabilities.
  2. Request information about vulnerability 1.
  3. Request information about vulnerability 2 and so on.

  Valid states include the following:

  * :summarize indicates that no vulnerability information has been fetched.
  * :describe indicates that vulnerability summaries have been fetched.
  * :ok indicates that complet vulnerability descriptions are ready to be served.
  * :done indicates that the stream has completed serving vulnerabilities.
  * :error indicates that the stream encountered an error from clair.
  """

  defstruct state: :summarize, vulns: [], platform: "", next_page: ""
end

defmodule Patches.StreamFn do
  @moduledoc """
  Functions for manipulating streams of vulnerabilities.
  """

  alias Patches.Stream

  def stream(vulns, next_page) when next_page == "" do
    IO.puts "Constructed a stream in done state"
    %Stream{ state: :done, vulns: vulns }
  end
  
  def stream(:error, reason) do
    IO.puts "Constructed a stream in error state"
    %Stream{ state: {:error, reason} }
  end

  def stream(vulns, next_page) do
    IO.puts "Constructed a stream in ok state"
    %Stream{ state: :ok, vulns: vulns, next_page: next_page }
  end

  def drain(s=%Stream{ state: :summarize }) do
    IO.puts "Drain state summarize"
    {:error, :not_ready, s}
  end

  def drain(s=%Stream{ state: :describe }) do
    IO.puts "Drain state describe"
    {:error, :not_ready, s}
  end

  def drain(s=%Stream{ state: :ok, vulns: vulns }) do
    IO.puts "Drain state ok"
    {:ok, vulns, %Stream{ s | state: :summarize, vulns: [] }}
  end
  
  def drain(%Stream{ state: :done, vulns: vulns }) do
    IO.puts "Drain state done"
    {:ok, vulns, %Stream{ state: :done, vulns: [] }}
  end

  def drain(s=%Stream{ state: {:error, reason} }) do
    IO.puts "Drain state error"
    {:error, reason, s}
  end

  def is_done?(%Stream{ state: :done }) do
    true
  end

  def is_done?(_stream) do
    false
  end
end
