defmodule GroveOfWisps.Repo.Migrations.CreateUserAuthTables do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS citext", ""

    create table(:user, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :email, :citext, null: false
      add :hashed_password, :string, null: false
      add :confirmed_at, :naive_datetime
      timestamps(type: :utc_datetime)
    end

    create unique_index(:user, [:email])

    create table(:user_tokens, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :users_id, references(:user, type: :binary_id, on_delete: :delete_all), null: false
      add :token, :binary, null: false
      add :context, :string, null: false
      add :sent_to, :string
      timestamps(updated_at: false)
    end

    create index(:user_tokens, [:users_id])
    create unique_index(:user_tokens, [:context, :token])
  end
end
