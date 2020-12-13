defmodule NetworkLab.Repo.Migrations.AddNetworkTopology do
  use Ecto.Migration

  def change do
    alter table("networks") do
      add :topology, :string
    end
  end
  
end
