defmodule NetworkLab.Messages.Message do

    use Ecto.Schema
    import Ecto.Changeset
    require Logger

    schema "messages" do
        field :network_id, :integer
        field :sender_id, :integer
        field :receiver_id, :integer

        field :proposition_id, :integer
        field :proposition_type, :string
        field :proposition_title, :string
        field :proposition, :string

        field :decision, :string
        field :decision_made_at, :naive_datetime
        field :position, :integer
        
        timestamps()
    end

    # insert changeset, do not permit params
    def insert_changeset(message, params \\ %{}) do
        # there is a problem with inserting messages, the action isn't there, 
        # so I will explicitly set it
        %{ cast(message, params, []) | action: :insert }
    end

    # permit decision
    def decision_changeset(message, params \\ %{}) do
        # create timestamp
        current_time = NaiveDateTime.truncate(NaiveDateTime.utc_now(),:second)
        # plug time of decision into params
        params = Map.put(params, "decision_made_at", current_time)
        # make a changeset
        cs = cast(message, params, [:decision, :decision_made_at])
        %{cs | action: :update}
    end

end