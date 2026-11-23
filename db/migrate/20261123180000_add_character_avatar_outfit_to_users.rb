# frozen_string_literal: true

class AddCharacterAvatarOutfitToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :character_avatar_outfit_id, :uuid
  end
end
