# frozen_string_literal: true

# == Schema Information
#
# Table name: inventory_transfer_reports
#
#  id                    :uuid             not null, primary key
#  aasm_state            :string           default("open"), not null
#  note                  :text
#  reason                :integer          default(0), not null
#  resolution_note       :text
#  reviewed_at           :datetime
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  fleet_id              :uuid
#  inventory_transfer_id :uuid             not null
#  reporter_id           :uuid
#  reviewed_by_id        :uuid
#
# Indexes
#
#  index_inventory_transfer_reports_on_fleet_id               (fleet_id)
#  index_inventory_transfer_reports_on_inventory_transfer_id  (inventory_transfer_id)
#  index_inventory_transfer_reports_on_reporter_id            (reporter_id)
#  index_inventory_transfer_reports_on_reviewed_by_id         (reviewed_by_id)
#  index_transfer_reports_on_open_created_at                  (created_at) WHERE ((aasm_state)::text = 'open'::text)
#  index_transfer_reports_on_transfer_and_reporter            (inventory_transfer_id,reporter_id) UNIQUE WHERE (reporter_id IS NOT NULL)
#
# Foreign Keys
#
#  fk_rails_...  (fleet_id => fleets.id) ON DELETE => cascade
#  fk_rails_...  (inventory_transfer_id => inventory_transfers.id) ON DELETE => cascade
#  fk_rails_...  (reporter_id => users.id) ON DELETE => nullify
#  fk_rails_...  (reviewed_by_id => admin_users.id) ON DELETE => nullify
#
FactoryBot.define do
  factory :inventory_transfer_report do
    association :inventory_transfer, factory: %i[inventory_transfer to_user]
    association :reporter, factory: :user
    reason { :spam }
  end
end
