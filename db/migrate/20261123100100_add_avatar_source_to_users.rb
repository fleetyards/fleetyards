# frozen_string_literal: true

class AddAvatarSourceToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :avatar_source, :integer, default: 0, null: false
  end
end
