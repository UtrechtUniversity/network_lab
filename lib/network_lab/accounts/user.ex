defmodule NetworkLab.Accounts.User do

    use Ecto.Schema
    import Ecto.Changeset
    require Logger

    schema "users" do
        field :username, :string
        field :role, :string
        field :status, :string

        field :condition_1, :string
        field :condition_2, :string

        field :alleged_ideology, :integer
        field :current_ideology, :integer
        field :ideology_conflict, :boolean
        field :ideology, :string

        field :access_token, :string
        field :exit_token, :string
        field :agreed_to_terms, :boolean
        field :agreed_to_personal_data, :boolean

        belongs_to :network, NetworkLab.Networks.Network
        field :node_id, :integer
        field :neighbour_ids, {:array, :integer}
        field :neighbour_info, :map
        field :started_at, :naive_datetime

        # this is for a pre-set workload
        field :workload, :map

        timestamps()
    end


    def user_changeset(user, params \\ %{}) do
        user
        |> cast(params, [:alleged_ideology, :current_ideology, :ideology_conflict,
            :ideology, :status, :agreed_to_terms, :agreed_to_personal_data])
        |> validate_acceptance(:agreed_to_terms, message: "Please agree to our terms of service.")
        |> validate_acceptance(:agreed_to_personal_data, message: "Please agree to our terms of data processing.")
        |> validate_required(:current_ideology, message: "Please select your political preference.")
        |> validate_required(:status)
    end


    def user_status_changeset(user, params \\ %{}) do
        user
        |> cast(params, [:status])
        |> validate_required(:status)
    end

    
    def network_changeset(user, params \\ %{}) do
        user
        |> cast(params, [:status, :condition_1, :condition_2, :network_id, :node_id, 
            :neighbour_ids, :neighbour_info, :started_at])
    end

end
