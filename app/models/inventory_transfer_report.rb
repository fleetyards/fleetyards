# frozen_string_literal: true

# Somebody saying a transfer should not have been sent.
#
# Filing one is not only a request for an admin to look: it declines the
# transfer and denies the sender in the same transaction, so the reporter gets
# relief immediately rather than waiting on a queue for something they could do
# themselves. The report is the additional step.
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
class InventoryTransferReport < ApplicationRecord
  include AASM

  paginates_per 30

  REASONS = {spam: 0, harassment: 1, scam: 2, other: 3}.freeze

  enum :reason, REASONS

  belongs_to :inventory_transfer
  belongs_to :reporter, class_name: "User", optional: true
  belongs_to :fleet, optional: true
  belongs_to :reviewed_by, class_name: "AdminUser", optional: true

  validates :note, presence: true, if: :other?
  # Matching the partial unique index. Filing again is not more signal, and it
  # should read as a rejected form rather than as a 500.
  validates :reporter_id, uniqueness: {scope: :inventory_transfer_id}, allow_nil: true

  scope :open_queue, -> { where(aasm_state: "open").order(created_at: :desc) }

  aasm timestamps: true, whiny_transitions: false do
    state :open, initial: true
    state :actioned
    state :dismissed

    event :action do
      transitions from: %i[open dismissed], to: :actioned
    end

    event :dismiss do
      transitions from: %i[open actioned], to: :dismissed
    end
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[aasm_state reason created_at updated_at reviewed_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[inventory_transfer reporter fleet]
  end

  # Who the report is about: the party that sent the transfer, not the person
  # who pressed the button on its behalf.
  def subject
    inventory_transfer&.sender_party
  end
end
