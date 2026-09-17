# frozen_string_literal: true

# A fleet's entitlement to the premium capabilities, as a dated record rather
# than a flag.
#
# Deliberately not Flipper (D1). A deploy prunes gate values, so paid access
# must not depend on a deploy-time reconciliation job; a gate can only grant,
# so a revocation cannot be expressed as one; and a flag records who has it now,
# never who had it when, or why, or who granted it. Those are the four reasons,
# and none of them is about shape.
# == Schema Information
#
# Table name: fleet_subscriptions
#
#  id                        :uuid             not null, primary key
#  ended_at                  :date
#  granted_via               :string           default("manual"), not null
#  note                      :text
#  started_at                :date             not null
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  fleet_id                  :uuid             not null
#  supporter_contribution_id :uuid
#
# Indexes
#
#  idx_on_fleet_id_started_at_ended_at_8e188918c2          (fleet_id,started_at,ended_at)
#  index_fleet_subscriptions_on_active_fleet               (fleet_id) UNIQUE WHERE (ended_at IS NULL)
#  index_fleet_subscriptions_on_supporter_contribution_id  (supporter_contribution_id) WHERE (supporter_contribution_id IS NOT NULL)
#
# Foreign Keys
#
#  fk_rails_...  (fleet_id => fleets.id) ON DELETE => cascade
#  fk_rails_...  (supporter_contribution_id => supporter_contributions.id) ON DELETE => nullify
#
class FleetSubscription < ApplicationRecord
  attr_accessor :update_reason, :update_reason_description, :author_id

  # Same gate as SupporterContribution: only an action somebody took files a
  # version, so a reconciler run leaves no trail of its own. `ended_at` is the
  # field that matters here -- a revocation has to be answerable for.
  has_paper_trail on: %i[create update],
    only: %i[fleet_id started_at ended_at granted_via supporter_contribution_id note],
    if: ->(record) { record.author_id.present? || PaperTrail.request.whodunnit.present? },
    meta: {
      author_id: :author_id,
      reason: :update_reason,
      reason_description: :update_reason_description
    }

  belongs_to :fleet
  belongs_to :supporter_contribution, optional: true

  # What granted this, which is not the same question as what platform the money
  # arrived on -- the contribution answers that, and a comp has no platform at
  # all. `contribution` is a row the reconciler seeded and may close again;
  # `manual` is a grant somebody made and it closes only by hand. A billing
  # provider later is another value here rather than a second record type.
  GRANTS = %w[contribution manual].freeze

  enum :granted_via, GRANTS.index_by(&:itself), prefix: :granted_via, default: "manual"

  validates :started_at, presence: true
  validate :ended_at_not_before_started_at

  # Open while `ended_at` is nil, and inclusive at both ends: a subscription
  # that starts today covers today, and one that ended today still did.
  scope :active_on, ->(date = Date.current) {
    where(started_at: ..date).where(ended_at: [nil, date..])
  }

  scope :open, -> { where(ended_at: nil) }

  # Seeded from a payment, so D9's reconciler may close it again. A grant with
  # no contribution behind it is somebody's decision and is left alone.
  #
  # Keyed on the provenance rather than on the id being present: deleting a
  # contribution nullifies the reference, and an id test would then reclassify
  # the row as a comp and leave the reconciler unable to close it. The two have
  # to agree, and `granted_via` is the one that survives.
  scope :seeded, -> { where(granted_via: "contribution") }

  def active_on?(date = Date.current)
    started_at <= date && (ended_at.nil? || ended_at >= date)
  end

  def open?
    ended_at.nil?
  end

  # `Fleet#subscribed?` memoises, so a write through here has to say so or the
  # instance that already asked keeps answering with what it saw. Only reaches
  # the fleet this row loads -- another instance elsewhere in the same request
  # still holds its own answer, which is why the memo is documented as
  # request-scoped rather than as a cache.
  after_commit :clear_fleet_entitlement_cache

  private def clear_fleet_entitlement_cache
    association(:fleet).target&.clear_entitlement_cache
  end

  private def ended_at_not_before_started_at
    return if ended_at.blank? || started_at.blank?
    return if ended_at >= started_at

    errors.add(:ended_at, :must_be_after_started_at)
  end
end
