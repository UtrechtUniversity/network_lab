defmodule NetworkLab.Repo.Migrations.CreateNetworksTable do
  use Ecto.Migration

  def change do

    create table(:networks) do

      add :name, :string
      add :condition, :string
      add :status, :string, default: "open"
      add :attached_users, :integer, default: 0

      add :dimensions, { :array, :integer }
      add :capacity, :integer, default: nil
      add :nodes, :map
      add :fill_sequence, { :array, :integer }
      add :user_mapping, :map
      add :node_mapping, :map
      add :neighbour_mapping, :map

      timestamps()
    end

    create index(:networks, [:name])

  end
end