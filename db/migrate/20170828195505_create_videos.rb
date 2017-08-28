class CreateVideos < ActiveRecord::Migration[5.1]
  def change
    create_table :videos, id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
      t.string :url
      t.integer :video_type
      t.boolean :enabled, default: false

      t.timestamps
    end
  end
end
