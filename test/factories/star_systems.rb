# frozen_string_literal: true

FactoryBot.define do
  factory :star_system do
    sequence(:code) { |n| "SYSTEM#{n}" }
    sequence(:name) { |n| "System #{n}" }
    position { [49.534718, -2.6339645, 16.475292] }
    system_type { "single_star" }
    affiliations { ["UEE"] }
    in_game { false }
  end

  factory :jump_tunnel do
    entry_system factory: :star_system
    exit_system factory: :star_system
    size { "medium" }
    bidirectional { true }
  end
end
