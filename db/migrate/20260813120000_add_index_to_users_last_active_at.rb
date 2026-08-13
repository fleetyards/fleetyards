class AddIndexToUsersLastActiveAt < ActiveRecord::Migration[8.1]
  def change
    add_index :users, :last_active_at
  end
end
