defmodule NetworkLab.Repo.Migrations.AddPositionToMessage do
  use Ecto.Migration

  def change do
    alter table("messages") do
      add :position, :integer, default: 0
    end
  end
  
end
