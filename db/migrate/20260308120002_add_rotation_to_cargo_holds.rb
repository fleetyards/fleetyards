class AddRotationToCargoHolds < ActiveRecord::Migration[7.2]
  def change
    add_column :cargo_holds, :rotation, :integer
  end
end
