# frozen_string_literal: true

class CreateCharacterAssets < ActiveRecord::Migration[8.1]
  def change
    create_table :character_assets, id: :uuid do |t|
      t.string :path, null: false
      t.string :etag
      t.bigint :size
      t.timestamps
    end
    add_index :character_assets, :path, unique: true
  end
end
