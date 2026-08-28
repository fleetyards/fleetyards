# frozen_string_literal: true

# == Schema Information
#
# Table name: sc_data_unlisted_models
#
#  id                     :uuid             not null, primary key
#  comparison             :string
#  decided_at             :datetime
#  decision               :string
#  first_seen_environment :string           not null
#  first_seen_version     :string           not null
#  identifier             :string           not null
#  last_seen_environment  :string           not null
#  last_seen_version      :string           not null
#  manufacturer_code      :string
#  name                   :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  base_model_id          :uuid
#  model_id               :uuid
#
# Indexes
#
#  index_sc_data_unlisted_models_on_base_model_id  (base_model_id)
#  index_sc_data_unlisted_models_on_decision       (decision)
#  index_sc_data_unlisted_models_on_identifier     (identifier) UNIQUE
#  index_sc_data_unlisted_models_on_model_id       (model_id)
#
# Foreign Keys
#
#  fk_rails_...  (base_model_id => models.id) ON DELETE => nullify
#  fk_rails_...  (model_id => models.id) ON DELETE => nullify
#
FactoryBot.define do
  factory :sc_data_unlisted_model do
    sequence(:identifier) { |n| "drak_newhull_#{n}" }
    name { "Drake Newhull" }
    manufacturer_code { "DRAK" }
    comparison { "unrelated" }

    first_seen_version { ScData::Source.version }
    first_seen_environment { ScData::Source.environment }
    last_seen_version { ScData::Source.version }
    last_seen_environment { ScData::Source.environment }

    trait :decided do
      decision { "ignored" }
      decided_at { Time.current }
    end
  end
end
