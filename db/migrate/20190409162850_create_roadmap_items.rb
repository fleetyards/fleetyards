class CreateRoadmapItems < ActiveRecord::Migration[5.2]
  def change
    create_table :roadmap_items, id: :uuid, default: -> { 'uuid_generate_v4()' }, force: :cascade do |t|
      t.integer :rsi_id
      t.integer :rsi_category_id
      t.integer :rsi_release_id
      t.string :release
      t.text :release_description
      t.string :name
      t.uuid :model_id
      t.text :body
      t.text :description
      t.boolean :released
      t.string :image
      t.integer :tasks
      t.integer :inprogress
      t.integer :completed

      t.timestamps
    end
  end
end
