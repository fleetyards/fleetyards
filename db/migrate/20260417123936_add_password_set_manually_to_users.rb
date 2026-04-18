class AddPasswordSetManuallyToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :password_set_manually, :boolean, default: false, null: false

    reversible do |dir|
      dir.up do
        # Users who signed up via OAuth have their account and first connection
        # created within seconds of each other. If the gap is larger than 1 minute,
        # the user registered with email/password first and connected OAuth later.
        execute <<~SQL
          UPDATE users SET password_set_manually = true
          WHERE id NOT IN (
            SELECT oc.user_id
            FROM omniauth_connections oc
            INNER JOIN users u ON u.id = oc.user_id
            WHERE oc.created_at - u.created_at < INTERVAL '1 minute'
          )
        SQL
      end
    end
  end
end
