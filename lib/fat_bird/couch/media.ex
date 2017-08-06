defmodule FatBrid.Couch.Media do
    alias FatBird.Couch.Db, as: Db
    
    defp save_media(db, type, item) do
        id = type<>rand()
        Db.write_document(db, id, %{type=>item}, :map)
        id
    end

    defp rand do
        15 |> :crypto.strong_rand_bytes() |> :base64.encode()
    end

     @doc"""
        this function saves some item to a database with a unique key
        It takes the db, type of thing being saved(must be the name field in the parent doc), the actual item, and the parent document
        
        This is useful for saving larger items such as pictures as we do not want
        to load a whole picture in to memory if we only need other attrubies of the parent document

        for example if you have a user doc with a field "picture", calling save attachment will 
            1. create a document with a unique id, that stores the picture
            2. put that id in the field "picture" in the parent document
    """
    def save_attachment(db, type, item, doc) do
         cond do 
            doc[type]==type -> 
                id = save_media(db, type, item)
                Db.update_document(db, doc, type, id, "picture saved")
                id
            true -> 
                id = doc[type]
                {:ok, old} = Db.get_document(db, id, "failed to get #{type} with id #{id} from database")
                Db.update_document(db, old, type, item, "updated #{id} document")
                id
        end
    end
end