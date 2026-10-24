# frozen_string_literal: true

class RemoveGuildedFromUsersAndFleets < ActiveRecord::Migration[8.1]
  def change
    remove_column :users, :guilded, :string
    remove_column :fleets, :guilded, :string
  end
end
