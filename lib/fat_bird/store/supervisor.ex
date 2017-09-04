defmodule FatBird.Store.Supervisor do
    use Supervisor
    import Supervisor.Spec
    
    alias FatBird.Locations.Server, as: Server
    alias FatBird.Couch.Base, as:  Base

    #TODO:: save ets tables in another ets so on restart we don't remake tables??
    
    def start_link do 
        Supervisor.start_link(__MODULE__, [], name: __MODULE__)
    end

    def init([]) do
        :ets.new(:info, [:named_table, :public])
        children = [
            worker(Server, [], restart: :permanent)
        ]

        supervise(children, strategy: :simple_one_for_one)
    end

    def add_location({:reload, city}) do
        res = Supervisor.start_child(__MODULE__, [:reload, city])
        save_table_ids(city)
        res
    end

    def add_location(city) do
        res = Supervisor.start_child(__MODULE__, [city])
        save_table_ids(city)
        res
    end

    def reload_all_locations do
        Base.all_locations()
        |>Enum.map(fn({city, _db_config}) -> 
            db_config = Base.get_location_db(city)
            res = Supervisor.start_child(__MODULE__, [:reload, {city, db_config}]) 
            save_table_ids(city)
            res
        end)
    end

end