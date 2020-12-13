defmodule NetworkLab.Repo.Migrations.AddLastUserToNetwork do
  use Ecto.Migration

  def change do
    alter table("networks") do
      add :started_at, :naive_datetime
      add :finished_at, :naive_datetime
    end
  end
end
