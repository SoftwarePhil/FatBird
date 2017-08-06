defmodule RentMe.Couch.Base do
    alias FatBird.Couch.Db, as: Db
    alias FatBird.Couch.Util, as: Util

    @moduledoc """
        This module acts as a store for all databases used in an application

        This is as an important persistant data layer 
     """

    #call this function on first start up
    def init_(app_name) do
        {:ok, db} = app_db(app_name)

        Db.write_document(db, "app", Poison.encode!(%{"dbs"=>[]}))
        {:ok, db}
    end

    def app_db(app_name) do
        Db.db_config(app_name)
    end

    def get_all_dbs(app_name) do
        with {:ok, dbs} <- Db.get_document(app_db(app_name), "app", "failed to get load #{app_name} databases document") do
            dbs = rent_me["dbs"]
        else
             _ -> {:error, "could not load databases"}
        end
    end

    def add_database(app_name, db) do
        app_db(app_name)
        |>Db.append_to_document("app", "dbs", db, "failed to add new database")
    end
end