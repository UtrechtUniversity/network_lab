defmodule NetworkLab.Repo.Migrations.ChangeWorkloadType do
  use Ecto.Migration

  def up do
    alter table(:users) do
      modify :workload, :map
    end
  end

  def down do
    alter table(:users) do
      modify :workload, :jsonb
    end
  end

end
