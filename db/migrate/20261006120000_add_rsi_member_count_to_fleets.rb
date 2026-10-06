# frozen_string_literal: true

class AddRsiMemberCountToFleets < ActiveRecord::Migration[8.1]
  def change
    add_column :fleets, :rsi_member_count, :integer
  end
end
