defmodule Patches.Stream do
  @moduledoc """
  The state of a stream of vulnerabilities from Clair.
  """

  defstruct state: :not_started, vulns: [], next_page: ""
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

  def drain(%Stream{ state: :not_started }) do
    IO.puts "Drain state not_started"
    {:error, :not_started, %Stream{}}
  end

  def drain(s=%Stream{ state: :ok, vulns: vulns }) do
    IO.puts "Drain state ok"
    {:ok, vulns, %Stream{ s | vulns: [] }}
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
