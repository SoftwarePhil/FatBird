
defmodule FatBird.Store.Server do
    use GenServer
    alias FatBird.Couch.Db, as: Db
    alias FatBird.Couch.Base, as: Base
    alias FatBird.Items.Store, as: ItemStore
    alias RentMe.Locations.Supervisor, as: Super

    #adding an item 
    #task to write to db
    #save whole item in map?? best way to search these? all items in an :ets table so we can query 

    # on restart/crash don't try to remake database, load items into server and items into ets table OR load from ets table
    # 
    def start_link(city) do
        with {:ok, db_config} <- init_db(city),
             {:ok, _db_config} <- Base.add_location(city, db_config),
             item_ets when item_ets != false <- ItemStore.create_ets(city),
             rental_ets when rental_ets != false <- RentalStore.create_ets(city),
             {:ok, pid} <- GenServer.start_link(__MODULE__, %{name: city, database: db_config, items: item_ets, rentals: rental_ets}, name: server_name(city)) do 
                {:ok, pid}
        else    
                {:error, msg} -> 
                    IO.inspect(msg)
                    {:error, "failed to create database/start server"}
        end 
    end

    #what if ets table exists already, it should not be remade
    def start_link(:reload, {city, db_config}) do
        IO.inspect({city, db_config})
        #what if ets table still exists (the ets table does not crash with this process)
        case Super.get_ets_table_ids(city) do
            {:ok, {items, rentals}} ->
                 GenServer.start_link(__MODULE__, %{name: city, database: db_config, items: items, rentals: rentals}, name: server_name(city))
            {:error, _} ->
                with item_ets when item_ets != false <- ItemStore.remake_ets(city, db_config),
                   rental_ets when rental_ets != false <- RentalStore.remake_ets(city, db_config),
                   {:ok, pid} <- GenServer.start_link(__MODULE__, %{name: city, database: db_config, items: item_ets, rentals: rental_ets}, name: server_name(city)) do 
                        {:ok, pid}
                else    
                  {:error, _msg} -> 
                    {:error, "failed to reload location server"}
            end 
        end
    end
    def start_link(:reload, city), do: start_link(:reload, {city, Base.get_location_db(city)})

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
    

    def state(name) do
        GenServer.call(server_name(name), :state)
    end

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

    def add_rental(item=%Item{}, user, rental_length) do
        rental = Rental.new_rental(user, item, rental_length)
        GenServer.call(server_name(item.city), {:new_rental, rental})
    end

    def search_items(city, term) do
        GenServer.call(server_name(city), {:search_items, term})
    end

    def get_item(city, id) do
        GenServer.call(server_name(city), {:get_item, id})
    end

    def test_crash(city) do
        GenServer.call(server_name(city), :crash)
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

    defp server_name(location) do
        {:global, location}
    end
end