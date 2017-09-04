defmodule FatBird.Store.Store do

    def create_ets(_location) do
        id = :ets.new(:location, [:set, :public])
        id
    end

    def remake_ets(location, database) do
        id = :ets.new(:location, [:set, :public])
  
        reload_items(database)
        |>Enum.each(fn(item) -> add_item({id, location}, Item.to_struct(item), :ets) end)
        id
    end

    def test_ets(id) do
        case :ets.info(id) do
            :undefined -> false
            _ -> true
        end
    end

    
    def add_item(ets, item, :ets) do
        #what if item exists in ets it will get overwritten? what if key exists in couchdb? should write happen here?

        case :ets.insert(ets, item) do
            true ->
                :ok
            _ -> {:error, "failed to add item"}
        end
    end
    #item has city now, remove city from params ..
    #shouldn't this add items to the db??
    def add_item(ets, item, database) do
       
        case :ets.insert(ets, item) do
            true ->
                id = elem(item, 0)
                Task.start(Db, :write_document, [database, id, Poison.encode!(item)])
                Task.start(Db, :append_to_document, [database, "items", "list", id, "failed to presist item in database"]) 
                {:ok, id}
            _ -> {:error, "failed to add item"}
        end
    end

    def all_items(ets) do
        :ets.tab2list(ets)
    end

    def get_item(ets, id) do
        case :ets.lookup(ets, id) do
            [{id, name, user, active, tags, des, price, location}] -> {:ok, %{id: id, user: user,name: name, active: active, tags: tags, description: des, price: price, location: location}}
            _ -> {:error, "item not found"}
        end
    end
    #{id, name, user, item_struct.active, item_struct.tags, item_struct.description, item_struct.price, item_struct.location}
    #this is bad, should use :ets.select, docs explicitly say not to do this
    #how to make this more generic??
    def search_items(ets, term) do
        :ets.tab2list(ets) |> Enum.filter(
            fn({_, item, _, _, _, _, _, _})-> 
               search_match?(term, item)
            end) 
            |> Enum.map(fn({id, name, user, active, tags, des, price, location}) -> 
                %{id: id, user: user,name: name, active: active, tags: tags, description: des, price: price, location: location}
            end)
    end
    def search_match?(term, name), do: String.downcase(name) |>String.match?(Regex.compile!("#{term}"))

    def reload_items(database) do
        {:ok, res} = Db.get_document(database, "items", "failed to get item list")

        res
        |>(fn(result) -> result["list"] end).()
        |>Enum.map(fn(item) -> 
                        {:ok, fetch} = Db.get_document(database, item, "item-not-found") 
                        fetch
                    end)
    end
end
end