defmodule NetworkLab.Repo.Migrations.AddCondition2ToNetwork do
  use Ecto.Migration

  def change do
    alter table("networks") do
      add :condition_2, :string
    end
    rename table("networks"), :condition, to: :condition_1
  end
  
end
