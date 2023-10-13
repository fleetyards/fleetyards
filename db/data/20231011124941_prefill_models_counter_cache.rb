# frozen_string_literal: true

class PrefillModelsCounterCache < ActiveRecord::Migration[7.0]
  def up
    User.find_each do |user|
      user.purchased_vehicles_count = user.purchased_vehicles.count
      user.wanted_vehicles_count = user.wanted_vehicles.count
      user.save
    end
  end

  def down
  end
end
