# frozen_string_literal: true

class AddMissingUniqueIndexes < ActiveRecord::Migration[6.0]
  def change
    add_index :commodities, :name, unique: true
    add_index :fleets, :fid, unique: true
    add_index :stations, :name, unique: true
    add_index :trade_routes, %i[origin_id destination_id], unique: true
  end
end
