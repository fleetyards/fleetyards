class DropRsiOrgs < ActiveRecord::Migration[5.1]
  def up
    drop_table :rsi_orgs if ActiveRecord::Base.connection.table_exists? 'rsi_orgs'
  end

  def down
  end
end
