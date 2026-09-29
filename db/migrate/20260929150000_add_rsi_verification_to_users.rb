# frozen_string_literal: true

class AddRsiVerificationToUsers < ActiveRecord::Migration[8.1]
  def up
    add_column :users, :rsi_verification_token, :string
    add_column :users, :rsi_verification_status, :string
    add_column :users, :rsi_verification_checked_at, :datetime
    add_column :users, :rsi_handle_verified_at, :datetime
    add_column :users, :rsi_handle_verified_via, :string

    # Citizen iD was the only way to verify a handle so far.
    execute <<~SQL
      UPDATE users SET rsi_handle_verified_via = 'citizenid' WHERE rsi_handle_verified
    SQL

    # A handle verified on several accounts keeps it on the one whose Citizen iD
    # connection answered last, the nearest thing to the latest proof.
    execute <<~SQL
      WITH ranked AS (
        SELECT users.id,
          row_number() OVER (
            PARTITION BY lower(users.rsi_handle)
            ORDER BY max(omniauth_connections.updated_at) DESC NULLS LAST, users.updated_at DESC
          ) AS position
        FROM users
        LEFT JOIN omniauth_connections
          ON omniauth_connections.user_id = users.id AND omniauth_connections.provider = 5
        WHERE users.rsi_handle_verified AND users.rsi_handle IS NOT NULL
        GROUP BY users.id
      )
      UPDATE users
      SET rsi_handle_verified = FALSE, rsi_handle_verified_via = NULL, updated_at = NOW()
      FROM ranked
      WHERE users.id = ranked.id AND ranked.position > 1
    SQL

    add_index :users, "lower(rsi_handle)", unique: true, where: "rsi_handle_verified",
      name: "index_users_on_verified_rsi_handle"
  end

  def down
    remove_index :users, name: "index_users_on_verified_rsi_handle"

    remove_column :users, :rsi_handle_verified_via
    remove_column :users, :rsi_handle_verified_at
    remove_column :users, :rsi_verification_checked_at
    remove_column :users, :rsi_verification_status
    remove_column :users, :rsi_verification_token
  end
end
