class AddOffsetsToCargoHolds < ActiveRecord::Migration[7.2]
  def change
    add_column :cargo_holds, :offset_x, :decimal, precision: 15, scale: 2
    add_column :cargo_holds, :offset_y, :decimal, precision: 15, scale: 2
    add_column :cargo_holds, :offset_z, :decimal, precision: 15, scale: 2
  end
end
