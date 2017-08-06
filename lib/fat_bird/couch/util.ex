defmodule RentMe.Couch.Util do
    def check_keys(keys, map) do
        case Enum.map(keys, fn k -> Map.has_key?(map, k) end) |> Enum.all? do
            true -> {:ok, map}
            false -> {:error, "missing"}
        end
    end
    
    def add_to_list(list, item) do
        case list do
            list when list == nil -> [item]
            _ ->
                list++[item]
                |>Enum.uniq()       
        end
    end

    def to_map(map) do
        for {key, val} <- map, into: %{}, do: {String.to_atom(key), val}
    end
end