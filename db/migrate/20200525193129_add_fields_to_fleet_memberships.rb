# frozen_string_literal: true

class AddFieldsToFleetMemberships < ActiveRecord::Migration[6.0]
  def change
    add_column :fleet_memberships, :ships_filter, :integer
    add_column :fleet_memberships, :hangar_group_id, :uuid
  end
end
