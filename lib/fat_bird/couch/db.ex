defmodule FatBird.Couch.Db do
    alias Couchdb.Connector.Writer
    alias Couchdb.Connector.Reader
    alias Couchdb.Connector
    alias FatBird.Couch.Util 

    #http://127.0.0.1:5984/_utils/index.html
    @couch_config %{protocol: "http", hostname: "localhost", database: __MODULE__, port: 5984}

    def init_db(name) do
        db = db_config(name)
        
        case Couchdb.Connector.Storage.storage_up(db) do
            {:ok, _msg} -> {:ok, db}
            {:error, msg} -> {:error, msg}
        end
    end

    def db_config(name) do
        %{@couch_config | database: "#{__MODULE__}_#{name}"}
    end
    
    @doc"""
        creates a new document with some id and body
        body must be JSON format
    """
    def write_document(db, key, body) do
        case Writer.create(db, body, key) do
            {:ok, _, _} -> {:ok, "document added"}
            {:error, _, _} -> {:error, "cound not add document"}
        end
    end

    def write_document(db, key, body, :map) do
        case Couchdb.Connector.create(db, body, key) do
            {:ok, _} -> {:ok, "document added"}
            {:error, _} -> {:error, "cound not add document"}
        end
    end

    @doc"""
    updates a the couch db docuement.
    Takes the old document, the field name, the new field,
    and a success message
    returns {:ok, new_document}
    """
    def update_document(db, old, field_name, new_field_data, success) do
            case Connector.update(db, %{old | field_name => new_field_data}) do
                {:ok, %{:headers => _h, :payload => _p}} -> {:ok, %{old | field_name => new_field_data}}
                {:error, _} -> {:error, "failed to update document (error doing #{success})"}
            end
    end

    def update_document_map(db, old, map, success) do
            case Connector.update(db, new = Map.merge(old, map)) do
                {:ok, %{:headers => _h, :payload => _p}} -> {:ok, new}
                {:error, _} -> {:error, "failed to update document (error doing #{success})"}
            end
    end


    @doc"""
    returns a document if found (not decoded from JSON)
    returns {:ok, document}
    """    
    def valid_document?(db, key, error) do
        case Reader.get(db, key) do
            {:ok, data}      -> {:found, data}
            {:error, _error} -> {:error, error}
        end
    end


    @doc"""
    returns a document if found decoded from JSON
    returns {:ok, document}
    """  
    def get_document(db, key, error) do
        case Reader.get(db, key) do
            {:ok, data} -> 
                {:ok, Poison.decode!(data)}
            {:error, _} -> {:error, error}  
        end
    end

    @doc"""
    If a document has a list, this will appened a single item to that list
    takes in the db, key field, item and error message
    """
    def append_to_document(db, key, field, item, error) do
        with {:ok, data} <- get_document(db, key, error),
             new_list <-  Util.add_to_list(data[field], item),
             update_document(db, data, field, new_list, error) do
                 {:ok, item}
                 
        else
            {:error, msg} -> {:error, msg}
        end
     
    end

    def delete_document(db, key, error) do
            case get_document(db, key, error) do
                {:ok, document} -> 
                    Couchdb.Connector.destroy(db, key, document["_rev"])
                    {:ok, "document deleted"}
            _ -> {:error, error}
            end
    end
end