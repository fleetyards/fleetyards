class AddRsiMembersToFleets < ActiveRecord::Migration[5.1]
  def change
    add_column :fleets, :rsi_members, :hstore, array: true, default: [], null: false
  end
end
