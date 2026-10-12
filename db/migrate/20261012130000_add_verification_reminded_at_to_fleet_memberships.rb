# frozen_string_literal: true

class AddVerificationRemindedAtToFleetMemberships < ActiveRecord::Migration[8.1]
  def change
    add_column :fleet_memberships, :verification_reminded_at, :datetime
  end
end
