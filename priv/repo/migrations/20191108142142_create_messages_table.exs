defmodule NetworkLab.Repo.Migrations.CreateMessagesTable do
  use Ecto.Migration

  def change do

    create table(:messages) do

      add :network_id, :integer
      add :sender_id, :integer
      add :receiver_id, :integer

      add :proposition_id, :integer
      add :proposition_type, :string
      add :proposition_title, :string
      add :proposition, :text

      add :decision, :string
      add :decision_made_at, :naive_datetime
    
      timestamps()

    end

    create index(:messages, [:network_id, :sender_id, :receiver_id])

  end
end
