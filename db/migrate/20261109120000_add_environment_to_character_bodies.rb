# frozen_string_literal: true

class AddEnvironmentToCharacterBodies < ActiveRecord::Migration[8.1]
  def change
    add_column :character_bodies, :environment, :jsonb
  end
end
