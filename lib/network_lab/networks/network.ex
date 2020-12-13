defmodule NetworkLab.Networks.Network do

    use Ecto.Schema
    import Ecto.Changeset
    require Logger

    schema "networks" do
        field :name, :string
        field :condition_1, :string
        field :condition_2, :string
        field :status, :string
        field :allow_messaging, :boolean
        field :attached_users, :integer

        field :topology, :string
        field :capacity, :integer, default: nil
        field :user_mapping, EctoIntKeyMap
        field :node_mapping, EctoIntKeyMap
        field :neighbour_mapping, EctoIntKeyMap

        field :started_at, :naive_datetime
        field :finished_at, :naive_datetime

        has_many :users, NetworkLab.Accounts.User
        timestamps()
    end

    def network_changeset(network, params \\ %{}) do
        network
        |> cast(params, [:status, :attached_users, :user_mapping, :node_mapping, :started_at, :allow_messaging])
    end

end
