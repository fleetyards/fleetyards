# frozen_string_literal: true

# == Schema Information
#
# Table name: commodity_builds
#
#  id             :uuid             not null, primary key
#  commodity_type :string
#  description    :text
#  environment    :string           not null
#  name           :string
#  version        :string           not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  commodity_id   :uuid             not null
#
# Indexes
#
#  index_commodity_builds_on_commodity_and_build             (commodity_id,environment,version) UNIQUE
#  index_commodity_builds_on_commodity_id                    (commodity_id)
#  index_commodity_builds_on_environment_and_commodity_type  (environment,commodity_type)
#  index_commodity_builds_on_environment_and_version         (environment,version)
#
# Foreign Keys
#
#  fk_rails_...  (commodity_id => commodities.id) ON DELETE => cascade
#
FactoryBot.define do
  factory :commodity_build do
    commodity
    environment { ScData::Source.environment }
    version { ScData::Source.version }

    sequence(:name) { |n| "#{Faker::Commerce.material} #{n}" }
    commodity_type { "metal" }
    description { Faker::Lorem.sentence }
  end
end
