# == Schema Information
#
# Table name: fleets
#
#  id                 :uuid             not null, primary key
#  background_image   :string
#  created_by         :uuid
#  description        :text
#  discord            :string
#  fid                :string
#  guilded            :string
#  homepage           :string
#  logo               :string
#  name               :string
#  normalized_fid     :string
#  public_fleet       :boolean          default(FALSE)
#  public_fleet_stats :boolean          default(FALSE)
#  rsi_sid            :string
#  sid                :string
#  slug               :string
#  ts                 :string
#  twitch             :string
#  youtube            :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
# Indexes
#
#  index_fleets_on_fid  (fid) UNIQUE
#
FactoryBot.define do
  factory :fleet do
    transient do
      members { [] }
      officers { [] }
      admins { [] }
    end

    name { Faker::Alphanumeric.alphanumeric(number: 10) }
    fid { Faker::Alphanumeric.alphanumeric(number: 3).upcase }
    public_fleet { true }

    after(:create) do |fleet, evaluator|
      evaluator.admins.each do |member|
        create(:fleet_membership, fleet: fleet, user: member, fleet_role: fleet.fleet_roles.ranked.first, aasm_state: :accepted)
      end

      evaluator.officers.each do |member|
        create(:fleet_membership, fleet: fleet, user: member, fleet_role: fleet.fleet_roles.ranked.second, aasm_state: :accepted)
      end

      evaluator.members.each do |member|
        create(:fleet_membership, fleet: fleet, user: member, fleet_role: fleet.fleet_roles.ranked.last, aasm_state: :accepted)
      end
    end
  end
end
