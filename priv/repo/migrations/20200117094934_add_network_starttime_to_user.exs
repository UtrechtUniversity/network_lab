defmodule NetworkLab.Repo.Migrations.AddNetworkStarttimeToUser do
  use Ecto.Migration

  def change do
    alter table("users") do
      add :started_at, :naive_datetime
    end
  end
  
end
