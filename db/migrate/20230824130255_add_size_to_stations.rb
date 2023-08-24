class AddSizeToStations < ActiveRecord::Migration[7.0]
  def change
    add_column :stations, :size, :integer
  end
end
