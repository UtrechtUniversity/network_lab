defmodule NetworkLab.Repo.Migrations.AddWorkloadToUser do
  use Ecto.Migration

  def change do
    alter table("users") do
      add :workload, :jsonb
      add :agreed_to_personal_data, :boolean, default: false
    end
  end

end
