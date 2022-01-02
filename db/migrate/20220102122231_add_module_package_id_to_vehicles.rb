class AddModulePackageIdToVehicles < ActiveRecord::Migration[6.1]
  def change
    add_column :vehicles, :module_package_id, :uuid
  end
end
