# frozen_string_literal: true

class AddNicknameToFleetMemberships < ActiveRecord::Migration[8.1]
  def change
    add_column :fleet_memberships, :nickname, :string
  end
end
