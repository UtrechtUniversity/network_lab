defmodule NetworkLab.Repo.Migrations.AddAllowSharingToNetwork do
  use Ecto.Migration

  def change do
    alter table("networks") do
      add :allow_messaging, :boolean, default: true
    end
  end
end
