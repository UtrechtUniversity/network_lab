defmodule NetworkLab.Repo.Migrations.CreateUsersTable do
  use Ecto.Migration

  def change do

    create table(:users) do

      add :username, :string
      add :role, :string, default: "participant"
      add :status, :string

      add :condition, :string
      add :color, :string

      add :access_token, :string
      add :exit_token, :string
      add :agreed_to_terms, :boolean, default: false

      add :network_id, references(:networks)
      add :node_id, :integer
      add :neighbours, { :array, :integer }

      timestamps()
    end

    create index(:users, [:access_token, :network_id])

  end
end


