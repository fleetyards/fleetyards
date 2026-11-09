# frozen_string_literal: true

class AddDefaultCharacterToCharacterBodies < ActiveRecord::Migration[8.1]
  def change
    change_table :character_bodies, bulk: true do |t|
      t.string :default_digest
      t.jsonb :default_md5s, null: false, default: {}
      t.jsonb :resolved
      t.string :resolved_digest
    end
  end
end
