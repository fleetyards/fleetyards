# == Schema Information
#
# Table name: fleet_roles
#
#  id              :uuid             not null, primary key
#  name            :string
#  permanent       :boolean
#  rank            :text
#  resource_access :text
#  slug            :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  fleet_id        :uuid             not null
#
# Indexes
#
#  index_fleet_roles_on_fleet_id           (fleet_id)
#  index_fleet_roles_on_fleet_id_and_rank  (fleet_id,rank) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (fleet_id => fleets.id)
#
FactoryBot.define do
  factory :fleet_role do
    name { "MyString" }
    resource_access { "MyString" }
    fleet { nil }
    permanent { false }
  end
end
