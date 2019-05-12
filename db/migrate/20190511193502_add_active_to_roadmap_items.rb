class AddActiveToRoadmapItems < ActiveRecord::Migration[5.2]
  def change
    add_column :roadmap_items, :active, :boolean
  end
end
