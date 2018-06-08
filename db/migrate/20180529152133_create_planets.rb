class CreatePlanets < ActiveRecord::Migration[5.2]
  def change
    create_table :planets, id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
      t.string :name
      t.string :slug
      t.uuid :starsystem_id
      t.uuid :planet_id

      t.timestamps
    end
  end
end
