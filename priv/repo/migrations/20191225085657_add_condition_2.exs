defmodule NetworkLab.Repo.Migrations.AddCondition2 do
  use Ecto.Migration

  def change do
    alter table("users") do
      add :condition_2, :string
    end
    rename table("users"), :condition, to: :condition_1
  end
  
end
