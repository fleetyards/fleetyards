class CleanupStationsSetup < ActiveRecord::Migration[5.2]
  def up
    drop_table :station_shops

    add_column :shops, :station_id, :uuid
    add_column :stations, :location, :string
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
