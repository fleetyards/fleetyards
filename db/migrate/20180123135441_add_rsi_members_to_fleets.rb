class AddRsiMembersToFleets < ActiveRecord::Migration[5.1]
  def change
    add_column :fleets, :rsi_members, :hstore, array: true, default: [], null: false
    add_index :fleets, :rsi_members, using: 'gin'
  end
end
