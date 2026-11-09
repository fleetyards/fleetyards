# frozen_string_literal: true

class AddFaceLibraryToCharacterBodies < ActiveRecord::Migration[8.1]
  def change
    change_table :character_bodies, bulk: true do |t|
      t.string :face_library
      t.string :faces_digest
      t.jsonb :face_md5s, null: false, default: {}
      t.string :skin_tone
    end
  end
end
