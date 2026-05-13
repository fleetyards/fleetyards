# frozen_string_literal: true

FactoryBot.define do
  factory :fleet_event_occurrence_state do
    fleet_event
    sequence(:occurrence_date) { |n| Date.today + n.days }
  end
end
