defmodule Mipha.Repo.Migrations.CreateUsersTeams do
  use Ecto.Migration

  def change do
    create table(:users_teams) do
      add :user_id, :integer
      add :team_id, :integer

      timestamps()
    end

  end
end
