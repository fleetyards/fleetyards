class AddLastActivityToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :last_active_at, :datetime
  end
end
