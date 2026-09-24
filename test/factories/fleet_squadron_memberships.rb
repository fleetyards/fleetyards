# frozen_string_literal: true

# == Schema Information
#
# Table name: fleet_squadron_memberships
#
#  id                  :uuid             not null, primary key
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  fleet_membership_id :uuid             not null
#  fleet_squadron_id   :uuid             not null
#
# Indexes
#
#  index_fleet_squadron_memberships_on_fleet_membership_id      (fleet_membership_id)
#  index_fleet_squadron_memberships_on_squadron_and_membership  (fleet_squadron_id,fleet_membership_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (fleet_membership_id => fleet_memberships.id)
#  fk_rails_...  (fleet_squadron_id => fleet_squadrons.id)
#
FactoryBot.define do
  factory :fleet_squadron_membership do
    fleet_squadron
    fleet_membership { association :fleet_membership, :accepted, fleet: fleet_squadron.fleet }
  end
end
