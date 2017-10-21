defmodule FatBird.Store.Store do
    alias FatBird.Couch.Db, as: Couch

    def create_ets(type) do
        id = :ets.new(type, [:set, :public])
        id
    end

    def remake_ets(type, database) do
        id = :ets.new(:location, [:set, :public])
  
        reload_items(database)
        |>Enum.each(fn(item) -> add_item(type, item, :ets) end)
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
                id = Couch.create_id()
                Task.start(Couch, :write_document, [database, id, Poison.encode!(item)])
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
   #not sure how to seach 
    def search_items(ets, term) do
        #best way to seach items??
        IO.inspect({ets, term})
    end

    
    ##make reload happen with views
    def reload_items(database) do
        {:ok, res} = Couch.get_document(database, "items", "failed to get item list")

        res
        |>(fn(result) -> result["list"] end).()
        |>Enum.map(fn(item) -> 
                        {:ok, fetch} = Couch.get_document(database, item, "item-not-found") 
                        fetch
                    end)
    end
end