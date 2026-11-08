# frozen_string_literal: true

class CreateCharacterFaces < ActiveRecord::Migration[8.1]
  def change
    create_table :character_faces, id: :uuid do |t|
      t.references :user, type: :uuid, null: false, foreign_key: {on_delete: :cascade}
      t.string :name, null: false
      t.string :token, null: false
      t.string :body, null: false
      t.string :dna_stamp
      t.string :gender_hash
      t.integer :format_version, null: false
      t.string :game_version
      t.jsonb :resolved
      t.string :resolved_digest
      t.timestamps
    end
    add_index :character_faces, :token, unique: true
    add_index :character_faces, %i[user_id name], unique: true

    add_reference :outfits, :character_face, type: :uuid, foreign_key: {on_delete: :nullify}
  end
end
