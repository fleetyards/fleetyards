# frozen_string_literal: true

# == Schema Information
#
# Table name: fleet_memberships
#
#  id              :uuid             not null, primary key
#  accepted_at     :datetime
#  declined_at     :datetime
#  hide_ships      :boolean          default(FALSE)
#  primary         :boolean          default(FALSE)
#  role            :integer
#  ships_filter    :integer          default("purchased")
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  fleet_id        :uuid
#  hangar_group_id :uuid
#  user_id         :uuid
#
require 'test_helper'

class FleetMembershipTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
