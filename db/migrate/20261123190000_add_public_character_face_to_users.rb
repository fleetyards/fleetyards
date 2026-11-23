# frozen_string_literal: true

class AddPublicCharacterFaceToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :public_character_face, :boolean, default: false, null: false
  end
end
