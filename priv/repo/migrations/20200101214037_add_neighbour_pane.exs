defmodule NetworkLab.Repo.Migrations.AddNeighbourPane do
  use Ecto.Migration

  def change do
    alter table("users") do
      add :neighbour_info, :map
    end
    rename table("users"), :neighbours, to: :neighbour_ids
  end
end
