# == Schema Information
#
# Table name: fleet_memberships
#
#  id                :uuid             not null, primary key
#  aasm_state        :string
#  accepted_at       :datetime
#  declined_at       :datetime
#  hide_ships        :boolean          default(FALSE)
#  invited_at        :datetime
#  invited_by        :uuid
#  primary           :boolean          default(FALSE)
#  requested_at      :datetime
#  role              :integer
#  ships_filter      :integer          default("all")
#  used_invite_token :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  fleet_id          :uuid
#  fleet_role_id     :uuid
#  hangar_group_id   :uuid
#  user_id           :uuid
#
# Indexes
#
#  index_fleet_memberships_on_fleet_role_id         (fleet_role_id)
#  index_fleet_memberships_on_user_id_and_fleet_id  (user_id,fleet_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (fleet_role_id => fleet_roles.id)
#
FactoryBot.define do
  factory :fleet_membership do
    fleet
    user
    fleet_role { fleet.fleet_roles.ranked.last }

    trait :invited do
      aasm_state { :invited }
    end
  end
end
