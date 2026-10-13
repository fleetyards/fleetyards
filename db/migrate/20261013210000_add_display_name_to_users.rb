# frozen_string_literal: true

class AddDisplayNameToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :display_name, :string
  end
end
