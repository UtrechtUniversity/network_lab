defmodule NetworkLab.Repo.Migrations.RemoveFieldsFromNetworks do
  use Ecto.Migration

  def up do
    alter table("networks") do
      remove :dimensions
      remove :nodes
      remove :fill_sequence
    end
  end

  def down do
    alter table("networks") do
      add :dimensions, { :array, :integer }
      add :nodes, :map
      add :fill_sequence, { :array, :integer }
    end
  end
end
