
defmodule FatBird.Store.Server do
    use GenServer
    alias FatBird.Couch.Db, as: Db
    alias FatBird.Couch.Base, as: Base
    alias FatBird.Items.Store, as: Store
    alias FatBird.Store.Supervisor, as: Super

    #adding an item 
    #task to write to db
    #save whole item in map?? best way to search these? all items in an :ets table so we can query 

    # on restart/crash don't try to remake database, load items into server and items into ets table OR load from ets table
    # 
    def start_link(type, id) do
        with {:ok, db_config} <- init_db(type),
             {:ok, _db_config} <- Base.add_location(type, db_config),
             ets_id when ets_id != false <- Store.create_ets(type),
             {:ok, pid} <- GenServer.start_link(__MODULE__, %{name: type, database: db_config, store: ets_id}, name: server_name(type, id)) do 
                {:ok, pid}
        else    
                {:error, msg} -> 
                    IO.inspect(msg)
                    {:error, "failed to create database/start server"}
        end 
    end

    #what if ets table exists already, it should not be remade
    def start_link(:reload, {type, id, db_config}) do
        #what if ets table still exists (the ets table does not crash with this process)
        case Super.get_ets_table_ids(type, id) do
            {:ok, ets_id} ->
                 GenServer.start_link(__MODULE__, %{name: type, database: db_config, store: ets_id}, name: server_name(type, id))
            {:error, _} ->
                with ets_id when ets_id != false <- Store.create_ets(type),
                   {:ok, pid} <- GenServer.start_link(__MODULE__, %{name: type, database: db_config, store: ets_id}, name: server_name(type, id)) do 
                        {:ok, pid}
                else    
                  {:error, _msg} -> 
                    {:error, "failed to reload location server"}
            end 
        end
    end
    def start_link(:reload, type, id, db_config), do: start_link(:reload, {type, id, db_config})

    def handle_call(:state, _from, state) do
        {:reply, state, state}
    end

    def handle_call({:new_item, item}, _from, state) do
        #get ets,
        #call add item?
        #failure?
        #write to db as task
        #reply with created item

        #the ets knows the city no need to pass it in again??
        {:ok, id} = ItemStore.add_item({state.items, state.name}, item, state.database)

        {:reply, {:ok, id}, state}
    end

    def handle_call({:new_rental, rental}, _from, state) do
        {:ok, id} = RentalStore.add_item(state.rentals, rental, state.database)

        {:reply, {:ok, id}, state}
    end

    def handle_call({:search_items, term}, _from, state) do
        %{items: items} = state
        list = ItemStore.search_items(items, term)
        {:reply, {:ok, list}, state}
    end

    def handle_call({:get_item, id}, _from, state) do
        %{items: items} = state
        {:ok, item} = ItemStore.get_item(items, id)
        {:reply, {:ok, item}, state}
    end
    

    def state(type, id) do
        GenServer.call(server_name(type, id), :state)
    end
"""
    def add_item(name, email, location, price, tags, description, picture) do
        #valid item??
        #use ecto to validate
        #figiure out how to save pictures ... thumbnails? seperate documents? just the id?
        user = User.get_user(email)
        item = Item.new_item(name, email, user.city, location, price, tags, description, picture)
        {:ok, id} = GenServer.call(server_name(user.city), {:new_item, item})
        Task.start(User, :add_item, [user, %{id: id, name: item.name}])
        {:ok, id}
    end
"""
    def add_rental(type, id) do
        #rental = Store.new_rental(user, item, rental_length)
        #GenServer.call(server_name(type, id), {:new_rental, rental})
    end

    def search_items(type, id, term) do
        GenServer.call(server_name(type, id), {:search_items, term})
    end

    def get_item(type, id) do
        GenServer.call(server_name(type, id), {:get_item, id})
    end

    def test_crash(type, id) do
        GenServer.call(server_name(type, id), :crash)
    end

    defp init_db(location) do
        location
        |>create_id()
        |>Db.init_db()
        |>set_up_city_doc()
    end

    defp create_id(location) do
        location
        |>String.downcase
        |>String.replace(", ", "_")
        |>String.replace(" ", "$")
    end

    def id_to_name(db_config) do
        db_config
        |>String.split("_")
        |>List.first
        |>String.replace("$", " ")
    end

    defp set_up_city_doc({:error, msg}), do: {:error, msg}
    defp set_up_city_doc({:ok, db}) do
        with {:ok, _msg} <- Db.write_document(db, "items", Poison.encode!(%{"list"=>[]})),
        {:ok, _msg} <- Db.write_document(db, "rentals", Poison.encode!(%{"list"=>[]})) do
            {:ok, db}
        else
            {:error, msg} -> {:error, msg}
        end
    end

    defp server_name(type, id) do
        {:global, "#{type}-#{id}"}
    end
end