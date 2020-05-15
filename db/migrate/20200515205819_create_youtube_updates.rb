class CreateYoutubeUpdates < ActiveRecord::Migration[6.0]
  def change
    create_table :youtube_updates, id: :uuid, default: -> { 'uuid_generate_v4()' }, force: :cascade do |t|
      t.string :video_id

      t.timestamps
    end
  end
end
