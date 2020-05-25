# frozen_string_literal: true

class PrefillFleetMembershipFields < ActiveRecord::Migration[6.0]
  def up
    FleetMembership.find_each do |membership|
      ships_filter = :purchased
      ships_filter = :hide if membership.hide_ships
      membership.update(ships_filter: ships_filter)
    end
  end

  def down; end
end
