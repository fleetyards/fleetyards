class AddCommittedToRoadmapItems < ActiveRecord::Migration[6.0]
  def change
    add_column :roadmap_items, :committed, :boolean, default: false
  end
end
