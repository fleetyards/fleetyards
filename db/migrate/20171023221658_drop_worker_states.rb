class DropWorkerStates < ActiveRecord::Migration[5.1]
  def up
    drop_table :worker_states if ActiveRecord::Base.connection.table_exists? 'worker_states'
  end

  def down
  end
end
