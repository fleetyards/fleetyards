class AddImageToRoadmapItems < ActiveRecord::Migration[5.2]
  def change
    add_column :roadmap_items, :store_image, :string
  end
end
