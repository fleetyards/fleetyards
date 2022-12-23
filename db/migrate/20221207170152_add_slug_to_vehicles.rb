class AddSlugToVehicles < ActiveRecord::Migration[6.1]
  def change
    add_column :vehicles, :slug, :string
  end
end
