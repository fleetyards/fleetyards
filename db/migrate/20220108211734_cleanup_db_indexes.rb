class CleanupDbIndexes < ActiveRecord::Migration[6.1]
  def change
    remove_index :trade_routes, [:origin_id]
    add_index :ahoy_events, [:time]

    add_column :users, :normalized_username, :string
    add_column :users, :normalized_email, :string

    User.find_each do |user|
      user.update(
        normalized_username: user.username.downcase,
        normalized_email: user.email.downcase
      )
    end
  end
end
