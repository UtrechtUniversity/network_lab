defmodule EctoIntKeyMap do
    use Ecto.Type
    
    def type, do: :map

    def cast(%{} = my_map), do: {:ok, my_map}
    def cast(_), do: :error

    def load(data) when is_map(data) do 
        { :ok, (for {key, val} <- data, into: %{}, do: {String.to_integer(key), val}) }
    end

    def dump(%{} = data), do: { :ok, data }
end