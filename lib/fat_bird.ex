defmodule FatBird do
  use Application
  alias FatBird.Couch.Base, as: Base

  def start(_type, _args) do 
    
    import Supervisor.Spec
  
      # Define workers and child supervisors to be supervised
      children = [
        # Start the endpoint when the application starts
        supervisor(FatBird.Store.Supervisor, []),
        # Start your own worker by calling: GoodApi2.Worker.start_link(arg1, arg2, arg3)
        # worker(GoodApi2.Worker, [arg1, arg2, arg3]),
      ]
  
      # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
      # for other strategies and supported options
      opts = [strategy: :simple_one_for_one, name: FatBird.Store.Supervisor]
      Supervisor.start_link(children, opts)
  end

  #loads all super types from Base
  def load_all do
    dbs = Base.get_dbs()
    IO.inspect(dbs)
    dbs
  end


  @moduledoc """
  Documentation for FatBird.
  """

  @doc """
  need to make a supervisor that makes all the children servers

  """
  def hello do
    :world
  end
end
