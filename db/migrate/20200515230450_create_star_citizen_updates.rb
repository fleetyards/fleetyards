class CreateStarCitizenUpdates < ActiveRecord::Migration[6.0]
  def change
    create_table :star_citizen_updates, id: :uuid, default: -> { 'uuid_generate_v4()' }, force: :cascade do |t|
      t.string :url
      t.string :title
      t.string :news_type
      t.string :news_sub_type
      t.string :slug

      t.timestamps
    end
  end
end
