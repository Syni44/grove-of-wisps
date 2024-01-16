defmodule GroveOfWisps.Profiles.Profiles do
  use Ecto.Schema
  import Ecto.Changeset
  @primary_key {:user_id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "profile" do
    field :display_name, :string, redact: true
    field :avatar, :string, redact: true
    field :location, :string, redact: true
    field :about_me, :string, redact: true

    timestamps(type: :utc_datetime)
  end

  @doc """
  A users changeset for registration.

  It is important to validate the length of both email and password.
  Otherwise databases may truncate the email without warnings, which
  could lead to unpredictable or insecure behaviour. Long passwords may
  also be very expensive to hash for certain algorithms.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.

    * `:validate_email` - Validates the uniqueness of the email, in case
      you don't want to validate the uniqueness of the email (like when
      using this changeset for validations on a LiveView form before
      submitting the form), this option can be set to `false`.
      Defaults to `true`.
  """
  def registration_changeset(profiles, attrs, opts \\ []) do
    profiles
    |> cast(attrs, [:display_name, :avatar])
    |> validate_display_name(opts)
    |> validate_avatar(opts)
  end

  defp validate_display_name(changeset, opts) do
    changeset
    |> validate_required([:display_name])
    |> validate_format(:display_name, ~r/^[a-zA-Z][a-zA-Z\d\-_~]+$/, message: "must only contain letters, numbers, -, _, ~, and start with a letter!")
    |> validate_length(:display_name, max: 32, message: "user name must be 32 characters or less!")
    |> maybe_validate_unique_display_name(opts)
  end

  defp validate_avatar(changeset, opts) do
    changeset
    |> validate_length(:password, min: 12, max: 72)

    # TODO: need to do upload validations: maybe see here https://www.poeticoding.com/step-by-step-tutorial-to-build-a-phoenix-app-that-supports-user-uploads/


    # Examples of additional password validation:
    # |> validate_format(:password, ~r/[a-z]/, message: "at least one lower case character")
    # |> validate_format(:password, ~r/[A-Z]/, message: "at least one upper case character")
    # |> validate_format(:password, ~r/[!?@#$%^&*_0-9]/, message: "at least one digit or punctuation character")
    |> maybe_hash_password(opts)
  end

  defp maybe_hash_password(changeset, opts) do
    hash_password? = Keyword.get(opts, :hash_password, true)
    password = get_change(changeset, :password)

    if hash_password? && password && changeset.valid? do
      changeset
      # Hashing could be done with `Ecto.Changeset.prepare_changes/2`, but that
      # would keep the database transaction open longer and hurt performance.
      |> put_change(:hashed_password, Pbkdf2.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end

  defp maybe_validate_unique_display_name(changeset, opts) do
    if Keyword.get(opts, :validate_display_name, true) do
      changeset
      |> unsafe_validate_unique(:display_name, GroveOfWisps.Repo)
      |> unique_constraint(:display_name)
    else
      changeset
    end
  end

  @doc """
  Confirms the account by setting `confirmed_at`.
  """
  def confirm_changeset(users) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    change(users, confirmed_at: now)
  end

  @doc """
  Verifies the password.

  If there is no users or the users doesn't have a password, we call
  `Pbkdf2.no_user_verify/0` to avoid timing attacks.
  """
  def valid_password?(%GroveOfWisps.Accounts.Users{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Pbkdf2.verify_pass(password, hashed_password)
  end

  def valid_password?(_, _) do
    Pbkdf2.no_user_verify()
    false
  end

  @spec validate_current_password(atom() | %{:data => any(), optional(any()) => any()}, any()) ::
          atom() | %{:data => any(), optional(any()) => any()}
  @doc """
  Validates the current password otherwise adds an error to the changeset.
  """
  def validate_current_password(changeset, password) do
    if valid_password?(changeset.data, password) do
      changeset
    else
      add_error(changeset, :current_password, "is not valid")
    end
  end
end
