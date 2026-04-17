class AddPasswordSetManuallyToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :password_set_manually, :boolean, default: false, null: false

    reversible do |dir|
      dir.up do
        execute <<~SQL
          UPDATE users SET password_set_manually = true
          WHERE id NOT IN (SELECT DISTINCT user_id FROM omniauth_connections)
        SQL
      end
    end
  end
end
