# == Schema Information
#
# Table name: fleet_roles
#
#  id                 :uuid             not null, primary key
#  name               :string
#  new_member_default :boolean          default(FALSE), not null
#  permanent          :boolean
#  rank               :text
#  resource_access    :text
#  slug               :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  discord_role_id    :string
#  fleet_id           :uuid             not null
#
# Indexes
#
#  index_fleet_roles_on_fleet_id_and_rank      (fleet_id,rank) UNIQUE
#  index_fleet_roles_on_one_default_per_fleet  (fleet_id) UNIQUE WHERE new_member_default
#
# Foreign Keys
#
#  fk_rails_...  (fleet_id => fleets.id)
#
FactoryBot.define do
  factory :fleet_role do
    fleet
    name { "Member" }
    resource_access { FleetRole.preset_privileges[:member] }
    permanent { false }

    trait :admin do
      name { "Admin" }
      resource_access { FleetRole.preset_privileges[:admin] }
      permanent { true }
    end

    trait :officer do
      name { "Officer" }
      resource_access { FleetRole.preset_privileges[:officer] }
    end

    trait :member do
      name { "Member" }
      resource_access { FleetRole.preset_privileges[:member] }
    end
  end
end
