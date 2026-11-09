# frozen_string_literal: true

class AddHoldPosesToCharacterBodies < ActiveRecord::Migration[8.1]
  def change
    add_column :character_bodies, :hold_poses, :jsonb, default: [], null: false
  end
end
