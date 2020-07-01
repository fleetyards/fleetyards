class AddBelongsToToTestTables < ActiveRecord::Migration[6.0]
  def change
    add_reference :test_tables, :models
  end
end
