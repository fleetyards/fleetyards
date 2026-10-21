# frozen_string_literal: true

class AddFirstSeenVersionToModels < ActiveRecord::Migration[8.1]
  def change
    add_column :models, :first_seen_version, :string
  end
end
