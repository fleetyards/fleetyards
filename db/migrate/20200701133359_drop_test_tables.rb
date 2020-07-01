class DropTestTables < ActiveRecord::Migration[6.0]
  def up
    drop_table :test_tables
  end

  def down
    create_table :test_tables, id: :uuid do |t|
      t.string :name
      t.references :model
    end
  end
end
