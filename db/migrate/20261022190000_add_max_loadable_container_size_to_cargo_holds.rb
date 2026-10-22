class AddMaxLoadableContainerSizeToCargoHolds < ActiveRecord::Migration[8.1]
  def change
    add_column :cargo_holds, :max_loadable_container_size_scu, :integer
  end
end
