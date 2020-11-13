class AddDescriptionToShops < ActiveRecord::Migration[6.0]
  def change
    add_column :shops, :description, :text
  end
end
