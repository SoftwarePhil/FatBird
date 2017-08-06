defmodule RentMe.Couch.Base do
    alias FatBird.Couch.Db, as: Db

    @moduledoc """
        This module acts as a store for all databases used in an application

        This is as an important persistant data layer 
     """

    #call this function on first start up
    def init_() do
        db = app_db() 
        |> Db.write_document("app", Poison.encode!(%{"dbs"=>[]}))
        
        {:ok, db}
    end

    def app_name() do
        Application.get_env(:fat_bird, :app_name)
    end

    #use a macro to generate a function the returns the apps name??
    #store it in a ets table?
    #where does it come from to on start with 
    def app_db() do
        app_name()
        |>Db.db_config()
    end

    def get_all_dbs() do
        with {:ok, doc} <- Db.get_document(app_db(), "app", "failed to get load databases document") do
           {:ok, doc["dbs"]}
        else
             _ -> {:error, "could not load databases"}
        end
    end

    #should this create a new database? prolly
    def add_database(db) do
        app_db()
        |>Db.append_to_document("app", "dbs", db, "failed to add new database")
    end
end