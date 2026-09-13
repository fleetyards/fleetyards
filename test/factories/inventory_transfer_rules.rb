# frozen_string_literal: true

# == Schema Information
#
# Table name: inventory_transfer_rules
#
#  id               :uuid             not null, primary key
#  effect           :integer          default(0), not null
#  note             :text
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  created_by_id    :uuid
#  fleet_id         :uuid
#  subject_fleet_id :uuid
#  subject_user_id  :uuid
#  user_id          :uuid
#
# Indexes
#
#  index_inventory_transfer_rules_on_created_by_id     (created_by_id)
#  index_inventory_transfer_rules_on_fleet_id          (fleet_id)
#  index_inventory_transfer_rules_on_subject_fleet_id  (subject_fleet_id)
#  index_inventory_transfer_rules_on_subject_user_id   (subject_user_id)
#  index_inventory_transfer_rules_on_user_id           (user_id)
#  index_transfer_rules_on_fleet_and_subject_fleet     (fleet_id,subject_fleet_id) UNIQUE WHERE ((fleet_id IS NOT NULL) AND (subject_fleet_id IS NOT NULL))
#  index_transfer_rules_on_fleet_and_subject_user      (fleet_id,subject_user_id) UNIQUE WHERE ((fleet_id IS NOT NULL) AND (subject_user_id IS NOT NULL))
#  index_transfer_rules_on_user_and_subject_fleet      (user_id,subject_fleet_id) UNIQUE WHERE ((user_id IS NOT NULL) AND (subject_fleet_id IS NOT NULL))
#  index_transfer_rules_on_user_and_subject_user       (user_id,subject_user_id) UNIQUE WHERE ((user_id IS NOT NULL) AND (subject_user_id IS NOT NULL))
#
# Foreign Keys
#
#  fk_rails_...  (created_by_id => users.id) ON DELETE => nullify
#  fk_rails_...  (fleet_id => fleets.id) ON DELETE => cascade
#  fk_rails_...  (subject_fleet_id => fleets.id) ON DELETE => cascade
#  fk_rails_...  (subject_user_id => users.id) ON DELETE => cascade
#  fk_rails_...  (user_id => users.id) ON DELETE => cascade
#
FactoryBot.define do
  factory :inventory_transfer_rule do
    user
    association :subject_user, factory: :user
    effect { :deny }

    trait :allow do
      effect { :allow }
    end

    trait :held_by_fleet do
      user { nil }
      fleet
    end

    trait :about_fleet do
      subject_user { nil }
      association :subject_fleet, factory: :fleet
    end
  end
end
