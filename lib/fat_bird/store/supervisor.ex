defmodule FatBird.Store.Supervisor do
    use Supervisor
    import Supervisor.Spec
    
    alias FatBird.Store.Server, as: Server
    alias FatBird.Couch.Base, as:  Base

    #TODO:: save ets tables in another ets so on restart we don't remake tables??
    
    @doc"""
        one supervisor per type
    """
    def start_link(type) do 
        Supervisor.start_link(__MODULE__, [], name: String.to_atom(type))
    end

    ##which type of server will get made, how do we figure that out??
    def init(type) do
        :ets.new(String.to_atom(type), [:named_table, :public])
        children = [
            worker(Server, [], restart: :permanent)
        ]

        supervise(children, strategy: :simple_one_for_one)
    end

    def add_type({:reload, type}) do
        res = Supervisor.start_child(__MODULE__, [:reload, type])
        save_table_ids(type)
        res
    end

    #this might not be module, the supervisor is actually the type as an atom
    def add_type(type) do
        ets_id = save_table_ids(type)
        res = Supervisor.start_child(__MODULE__, [type, ets_id])
        res
    end

    def reload_all_types(type) do
        Base.get_dbs(type)
        |>Enum.map(fn(type) -> 
            ets_id = save_table_ids(type)
            Supervisor.start_child(__MODULE__, [:reload, type, ets_id]) 
        end)
    end

    @doc"""
        This will save the ets id of a type.  We will have 1 Supervisor per type and
        types will have subtypes. 
    """
    def save_table_ids(type) do
        %{:ets=>ets} = Server.state(type)
        :ets.insert(String.to_atom(type), ets)
        ets
    end

    @doc"""
        this wil get the ets id of a particular server.  Since servers can crash we
        do not want to remake the ets tables, they will not crash since this supervisor 
        is in charge of making them 
    """
    def get_ets_table_ids(type) do
        case :ets.lookup(String.to_atom(type), :ets) do
            [] -> {:error, "type never created"}
            [{id, ets}] -> {:ok, {id, ets}}
        end
    end
end