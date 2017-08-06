defmodule RentMe.Couch.Base do
    alias RentMe.Couch.Db, as: Db
    alias RentMe.Couch.Util, as: Util

    @moduledoc """
        This module will act as the connection the the rentme_db which will hold
        the names of all locations and a refrence to the user_db.

        This acts as an important persistant data layer 
     """

     @rent_me "store"
     @rent_me_users "users"

    #call this function on first start up
    def init_rent_me do
        {:ok, db} = Db.init_db(@rent_me)
        {:ok, db_users} = Db.init_db(@rent_me_users)

        Db.write_document(db, "app", Poison.encode!(%{"locations"=>[], "user_db"=>db_users}))
        Db.write_document(db_users, "users", Poison.encode!(%{"users"=>[]}))
        {:ok, db}
    end

    def rent_me do
        Db.db_config(@rent_me)
    end

    def rent_me_users_db do
        Db.db_config(@rent_me_users)
    end

    #think about the best way to to store db information, does it make sense to have the key be the city name??
    #maybe have the whole thing be a map so what we can just pass in the location name
    #that would simplify the get location function
    def add_location(location, db) do
        Db.append_to_document(rent_me(), "app", "locations", %{location => db}, "failed to add new location")
    end

    def get_location_db(location) do
        with {:ok, rent_me} <- Db.get_document(rent_me(), "app", "failed to get load rentme document") do
            db_map = rent_me["locations"]
            |>Enum.find(fn(map) -> 
                cond do
                    Map.keys(map) == [location] -> true
                    true -> false
                end
            end)
            db_map[location] |> Util.to_map()
        else
             _ -> {:error, "could not load location"}
        end
    end

    def all_locations do
        with {:ok, rent_me} <- Db.get_document(rent_me(), "app", "failed to get load rentme document") do
            rent_me["locations"]
            |>Enum.map(fn(map) -> 
                [city] = Map.keys(map)
                {city, map[city] |> Util.to_map()}
            end)
        else
             _ -> {:error, "could not load location"}
        end
    end

    def all_users do
        with {:ok, users} <- Db.get_document(rent_me_users_db(), "users", "failed to get load rentme document") do
            users["users"]
        else
             _ -> {:error, "could not load location"}
        end
    end

    def add_user(user) do
        Db.append_to_document(rent_me_users_db(), "users", "users", user, "failed to add new location")
    end
end