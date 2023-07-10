class AddSlugToVehicles < ActiveRecord::Migration[7.0]
  def change
    add_column :vehicles, :slug, :string
  end
end
