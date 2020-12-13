defmodule NetworkLab.Repo.Migrations.RenameUserColor do
  use Ecto.Migration

  def change do
    rename table(:users), :color, to: :ideology
  end
end
