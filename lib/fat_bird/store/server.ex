
defmodule FatBird.Store.Server do
    use GenServer
    alias FatBird.Couch.Db, as: Db
    alias FatBird.Couch.Base, as: Base
    alias FatBird.Store.Store, as: Store
    alias FatBird.Store.Supervisor, as: Super

    #adding an item 
    #task to write to db
    #save whole item in map?? best way to search these? all items in an :ets table so we can query 

    # on restart/crash don't try to remake database, load items into server and items into ets table OR load from ets table
    # 
    def start_link(type) do
        with {:ok, db_config} <- init_db(type),
             ets_id when ets_id != false <- Store.create_ets(type),
             {:ok, pid} <- GenServer.start_link(__MODULE__, %{name: type, database: db_config, store: ets_id}, name: server_name(type)) do 
                {:ok, pid}
        else    
                {:error, msg} -> 
                    IO.inspect(msg)
                    {:error, "failed to create database/start server"}
        end 
    end

    #what if ets table exists already, it should not be remade
    def start_link(:reload, type, db_config) do
        #what if ets table still exists (the ets table does not crash with this process)
        case Super.get_ets_table_ids(type) do
            {:ok, ets_id} ->
                 GenServer.start_link(__MODULE__, %{name: type, database: db_config, store: ets_id}, name: server_name(type))
            {:error, _} ->
                with ets_id when ets_id != false <- Store.create_ets(type),
                   {:ok, pid} <- GenServer.start_link(__MODULE__, %{name: type, database: db_config, store: ets_id}, name: server_name(type)) do 
                        {:ok, pid}
                else    
                  {:error, _msg} -> 
                    {:error, "failed to reload location server"}
            end 
        end
    end

    def handle_call(:state, _from, state) do
        {:reply, state, state}
    end

    def handle_call({:new_item, _item}, _from, state) do
        #get ets,
        #call add item?
        #failure?
        #write to db as task
        #reply with created item

        #the ets knows the city no need to pass it in again??

        {:reply, :ok, state}
    end


    def handle_call({:search_items, term}, _from, state) do
        %{items: items} = state
        list = Store.search_items(items, term)
        {:reply, {:ok, list}, state}
    end

    def handle_call({:get_item, id}, _from, state) do
        %{store: store} = state
        {:ok, item} = Store.get_item(store, id)
        {:reply, {:ok, item}, state}
    end
    

    def state(type) do
        GenServer.call(server_name(type), :state)
    end

    def add_item(type, item) do
        #valid item??
        #use ecto to validate
        #figiure out how to save pictures ... thumbnails? seperate documents? just the id?
        Task.start(Store, :add_item, [type, item])
        {:ok, item}
    end

    def search_items(type, term) do
        GenServer.call(server_name(type), {:search_items, term})
    end

    def get_item(type, id) do
        GenServer.call(server_name(type), {:get_item, id})
    end

    def test_crash(type) do
        GenServer.call(server_name(type), :crash)
    end

    defp init_db(type) do
        type
        |>Base.add_database(type)
    end

    defp server_name(type) do
        {:global, type}
    end
end