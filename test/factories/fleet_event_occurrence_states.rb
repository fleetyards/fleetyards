# frozen_string_literal: true

# == Schema Information
#
# Table name: fleet_event_occurrence_states
#
#  id                        :uuid             not null, primary key
#  briefing                  :text
#  cancelled_at              :datetime
#  cancelled_reason          :text
#  cover_image_preset        :string
#  description               :text
#  discord_synced_at         :datetime
#  location                  :string
#  locked_at                 :datetime
#  meetup_location           :string
#  occurrence_date           :date             not null
#  scenario                  :string
#  starting_soon_notified_at :datetime
#  status                    :string
#  title                     :string
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  discord_event_id          :string
#  fleet_event_id            :uuid             not null
#
# Indexes
#
#  idx_fleet_event_occurrence_states_on_event_and_date  (fleet_event_id,occurrence_date) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (fleet_event_id => fleet_events.id)
#
FactoryBot.define do
  factory :fleet_event_occurrence_state do
    fleet_event
    sequence(:occurrence_date) { |n| Date.today + n.days }
  end
end
