class DropTaskForcesTable < ActiveRecord::Migration[5.1]
  def up
    drop_table :task_forces if ActiveRecord::Base.connection.table_exists? 'task_forces'
  end

  def down
  end
end
