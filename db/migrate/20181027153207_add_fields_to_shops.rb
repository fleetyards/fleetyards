class AddFieldsToShops < ActiveRecord::Migration[5.2]
  def change
    add_column :shops, :rental, :boolean, default: false
    add_column :shops, :buying, :boolean, default: false
    add_column :stations, :status, :integer
    add_column :components, :description, :text
    add_column :components, :store_image, :string
    add_column :commodities, :description, :text
    add_column :commodities, :store_image, :string
  end
end
