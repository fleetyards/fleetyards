# frozen_string_literal: true

# == Schema Information
#
# Table name: vehicle_upgrades
#
#  id                   :uuid             not null, primary key
#  rsi_pledge_synced_at :datetime
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  model_upgrade_id     :uuid
#  rsi_pledge_id        :string
#  vehicle_id           :uuid
#
require "test_helper"

class VehicleUpgradeTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
