defmodule NetworkLab.Repo.Migrations.AddSecondColorToUser do
  use Ecto.Migration

  def change do
    alter table("users") do
      add :alleged_ideology, :integer
      add :current_ideology, :integer
      add :ideology_conflict, :boolean, default: false 
    end
  end
end
