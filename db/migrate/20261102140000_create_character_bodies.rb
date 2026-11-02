class CreateCharacterBodies < ActiveRecord::Migration[8.1]
  def change
    create_table :character_bodies, id: :uuid do |t|
      t.string :key, null: false
      t.string :views_digest
      t.jsonb :view_md5s, null: false, default: {}
      t.timestamps
    end
    add_index :character_bodies, :key, unique: true
  end
end
