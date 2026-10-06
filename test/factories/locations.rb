# == Schema Information
#
# Table name: locations
#
#  id                         :uuid             not null, primary key
#  always_shown               :boolean          default(FALSE), not null
#  appearance_seed            :jsonb            not null
#  body_type                  :string
#  color                      :string
#  description                :text
#  facilities                 :jsonb
#  game_type                  :string
#  kind                       :string
#  mission_template_refs      :text             default([]), not null, is an Array
#  name                       :string
#  quantum_travel_destination :boolean          default(FALSE), not null
#  resources                  :jsonb            not null
#  sc_key                     :string           not null
#  sc_refs                    :text             default([]), not null, is an Array
#  shown_on_starmap           :boolean          default(FALSE), not null
#  shown_with_parent_only     :boolean          default(FALSE), not null
#  slug                       :string           not null
#  version                    :string
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  map_parent_id              :uuid
#  parent_id                  :uuid
#  system_id                  :uuid
#
# Indexes
#
#  index_locations_on_map_parent_id          (map_parent_id)
#  index_locations_on_mission_template_refs  (mission_template_refs) USING gin
#  index_locations_on_name                   (name)
#  index_locations_on_parent_id              (parent_id)
#  index_locations_on_sc_key                 (sc_key) UNIQUE
#  index_locations_on_sc_refs                (sc_refs) USING gin
#  index_locations_on_slug                   (slug) UNIQUE
#  index_locations_on_system_id              (system_id)
#  index_locations_on_version                (version)
#
# Foreign Keys
#
#  fk_rails_...  (map_parent_id => locations.id) ON DELETE => nullify
#  fk_rails_...  (parent_id => locations.id) ON DELETE => nullify
#  fk_rails_...  (system_id => locations.id) ON DELETE => nullify
#
FactoryBot.define do
  factory :location do
    sequence(:name) { |n| "Everus Harbor #{n}" }
    sequence(:sc_key) { |n| "RR_HUR_LEO_#{n}" }
    sc_refs { [Digest::UUID.uuid_v5(Digest::UUID::DNS_NAMESPACE, "location-#{sc_key}")] }
    description { "A rest stop in Hurston's orbit." }
    kind { "station" }
    game_type { "Manmade" }
    shown_on_starmap { true }
    quantum_travel_destination { true }
    version { ScData::Source.version }

    transient { with_build { true } }

    # Mirrors what a load leaves behind: the row and the build describing it.
    after(:create) do |location, evaluator|
      next unless evaluator.with_build
      next if location.version.blank?

      location.builds.create!(
        environment: ScData::Source.environment,
        version: location.version,
        **location.attributes.symbolize_keys.slice(*LocationBuild::FACTS)
      )

      location.association(:build).reset
      location.association(:last_build).reset
    end

    trait :without_build do
      with_build { false }
    end
  end
end
