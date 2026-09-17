# frozen_string_literal: true

# == Schema Information
#
# Table name: supporter_contributions
#
#  id                  :uuid             not null, primary key
#  amount_cents        :integer          not null
#  anonymous           :boolean          default(FALSE), not null
#  claim_key           :string
#  currency            :string           default("EUR"), not null
#  ended_at            :date
#  linked_via          :string
#  name                :string
#  note                :text
#  payer_email         :string
#  recurring           :boolean          default(FALSE), not null
#  source              :string
#  source_amount_cents :integer
#  source_currency     :string
#  started_at          :date             not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  fleet_id            :uuid
#  kofi_transaction_id :string
#  patreon_member_id   :string
#  patreon_user_id     :string
#  user_id             :uuid
#
# Indexes
#
#  index_supporter_contributions_on_fleet_id                (fleet_id) WHERE (fleet_id IS NOT NULL)
#  index_supporter_contributions_on_kofi_transaction_id     (kofi_transaction_id) UNIQUE WHERE (kofi_transaction_id IS NOT NULL)
#  index_supporter_contributions_on_linked_via              (linked_via) WHERE (linked_via IS NOT NULL)
#  index_supporter_contributions_on_patreon_member_id       (patreon_member_id) UNIQUE WHERE (patreon_member_id IS NOT NULL)
#  index_supporter_contributions_on_patreon_user_id         (patreon_user_id) WHERE (patreon_user_id IS NOT NULL)
#  index_supporter_contributions_on_payer_email             (payer_email) WHERE (payer_email IS NOT NULL)
#  index_supporter_contributions_on_recurring_and_ended_at  (recurring,ended_at)
#  index_supporter_contributions_on_started_at              (started_at)
#  index_supporter_contributions_on_user_id                 (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (fleet_id => fleets.id) ON DELETE => nullify
#  fk_rails_...  (user_id => users.id)
#
class SupporterContribution < ApplicationRecord
  attr_accessor :update_reason, :update_reason_description, :author_id

  # Only an admin action sets `author_id`, so a loader write files nothing. The
  # gate is not tidiness: the UEX sync rewrites all 232 commodities and 1,526 of
  # 4,830 equipment rows a week, and versioning those unconditionally would bury
  # the handful of real edits the way Fleet's touch versions already do.
  #
  # A signed-in `whodunnit` counts too, because a supporter nominating a fleet
  # is a real edit to a field that decides entitlement -- "why did my fleet lose
  # access" is answered by when the nomination changed. It widens nothing else:
  # the importers and the Ko-fi webhook run with no whodunnit at all.
  has_paper_trail on: %i[update],
    only: %i[
      name amount_cents currency anonymous recurring
      started_at ended_at note user_id payer_email claim_key source fleet_id
    ],
    if: ->(record) { record.author_id.present? || PaperTrail.request.whodunnit.present? },
    meta: {
      author_id: :author_id,
      reason: :update_reason,
      reason_description: :update_reason_description
    }
  paginates_per 30

  # Touch so a linked account's cached public profile picks the badge up.
  belongs_to :user, optional: true, touch: true

  # Which fleet this contribution is *for*, chosen by the supporter who made it.
  #
  # Deliberately a field rather than something derived from the roster: the
  # obvious alternative -- any accepted admin of the fleet is a supporter --
  # fails in both directions. Somebody who admins five fleets would upgrade all
  # five, and a fleet would lose what it had the day an admin who was never the
  # payer left. Sponsorship is a fact about the money, not about the roster.
  belongs_to :fleet, optional: true

  # Nullified rather than destroyed when the contribution goes, so a grant the
  # reconciler made survives its own payment being deleted -- `granted_via` is
  # what keeps it identifiable after that.
  has_many :fleet_subscriptions, dependent: :nullify

  DEFAULT_SORTING_PARAMS = "started_at desc"
  ALLOWED_SORTING_PARAMS = [
    "startedAt asc", "startedAt desc",
    "endedAt asc", "endedAt desc",
    "amountCents asc", "amountCents desc",
    "name asc", "name desc",
    "createdAt asc", "createdAt desc"
  ]

  # The platform the money arrived on. Patreon and Ko-fi are the two an importer
  # writes; the rest only ever come from an admin, who is recording a payment
  # that reached a platform we have no feed from. It does not mean "entered by
  # hand", which a patreon_member_id or kofi_transaction_id answers on its own.
  #
  # Null is "nobody stated one", and it is deliberately not the same as `other`.
  # `other` is a statement -- a platform, just not one of these -- and most rows
  # without a source are not making it; they are rows nobody was asked about.
  # Collapsing the two would lose the distinction permanently, because after the
  # fact there is nothing to tell them apart by.
  SOURCES = %w[patreon kofi buymeacoffee paypal other].freeze

  enum :source, SOURCES.index_by(&:itself)

  # Which rule linked the row, in the order Supporters::Linker tries them. Null
  # while nothing is linked; `manual` is the one nobody derives -- an admin
  # naming the account outranks every rule, so it is recorded as its own answer
  # rather than left blank.
  LINK_RULES = %w[patreon_account claim_key payer_email manual].freeze

  enum :linked_via, LINK_RULES.index_by(&:itself), prefix: :linked_via

  validates :amount_cents, presence: true, numericality: {greater_than: 0, only_integer: true}
  validates :currency, presence: true
  validates :started_at, presence: true
  validates :user, presence: true, if: :user_id?
  validates :claim_key, format: {with: SupporterClaimKey::CANONICAL}, allow_nil: true
  validate :ended_at_after_started_at
  validate :nominated_fleet_is_the_payers_own

  before_validation :force_anonymous_when_name_blank
  before_validation :normalize_payer_email
  before_validation :normalize_claim_key
  before_save :stamp_link_source

  scope :active_now, ->(date = Date.current) { active_in(date.beginning_of_month, date.end_of_month) }

  scope :active_in, ->(month_start, month_end) {
    where(
      "(recurring = ? AND started_at BETWEEN ? AND ?) OR " \
      "(recurring = ? AND started_at <= ? AND (ended_at IS NULL OR ended_at >= ?))",
      false, month_start, month_end,
      true, month_end, month_start
    )
  }

  # Stored trimmed and downcased so every lookup can compare it directly. The
  # platforms are not careful about this -- Patreon hands back names like
  # "Elfwyn " -- and an address with a stray space matches nothing, silently.
  private def normalize_payer_email
    self.payer_email = payer_email&.strip&.downcase.presence
  end

  # Anything key-shaped is stored in its canonical form, however it was typed.
  # Anything else is left as entered so the format validation can reject it --
  # normalising it to nil would turn a typo into silence, which is the failure
  # a dedicated field exists to avoid.
  private def normalize_claim_key
    self.claim_key = claim_key.presence
    return if claim_key.blank?

    self.claim_key = SupporterClaimKey.normalize(claim_key) || claim_key.strip
  end

  # Supporters::Linker names the rule it used in the same write, so a link that
  # arrives without one came from somewhere else -- an admin picking an account
  # in the form, a console, a fixture -- and `manual` is what all of those are.
  private def stamp_link_source
    return unless will_save_change_to_user_id?
    return if will_save_change_to_linked_via?

    self.linked_via = user_id.present? ? "manual" : nil
  end

  def self.ransackable_attributes(auth_object = nil)
    [
      "name", "amount_cents", "currency", "anonymous", "recurring",
      "started_at", "ended_at", "note", "source", "patreon_member_id",
      "kofi_transaction_id", "payer_email", "linked_via",
      "created_at", "updated_at", "id", "user_id", "fleet_id"
    ]
  end

  def self.ransackable_associations(auth_object = nil)
    ["user", "fleet"]
  end

  def self.monthly_total(date = Date.current)
    active_now(date).sum(:amount_cents)
  end

  # The field an admin filled in wins over a key found in the donation message:
  # the message is what the donor wrote, the field is what an admin read it as.
  def claim_key_for_linking
    claim_key.presence || SupporterClaimKey.extract(note)
  end

  # The last day this contribution still counts, or nil for an open-ended
  # recurring pledge, which has no last day until somebody ends it.
  #
  # The month is the unit throughout -- `active_in` matches a pledge ended on
  # the 5th for the whole of that month, and `monthly_total` counts it there --
  # so cover runs to the end of the month, not to the date itself. Answering
  # `ended_at` would have put a date already past next to a badge still reading
  # as live.
  def active_until
    return ended_at&.end_of_month if recurring?

    started_at.end_of_month
  end

  # The Ruby half of `active_in`, so a preloaded association can be filtered
  # without asking the database again. It sits next to the scope because the
  # two have to agree; `active_in_matches_the_scope` holds them to it.
  def active_in?(month_start, month_end)
    return started_at.between?(month_start, month_end) unless recurring?

    started_at <= month_end && (ended_at.nil? || ended_at >= month_start)
  end

  def formatted_amount
    format("%.2f %s", amount_cents.to_f / 100, currency)
  end

  def display_name
    name.presence || user&.username || I18n.t("messages.supporter_contributions.anonymous_name")
  end

  # Nil whenever the contribution must not be attributed publicly, so callers
  # can fall back to their own anonymous wording.
  def public_name
    return if anonymous?

    name.presence || user&.username
  end

  # Only usernames with a reachable public hangar, otherwise the profile link
  # we render would land on a 404.
  def public_profile_username
    return if anonymous?

    user&.username if user&.public_hangar?
  end

  # A nomination says what *this* money is for, so it needs a payer to have said
  # it and a fleet that payer actually belongs to. Without the first there is
  # nobody whose choice it is; without the second a contribution could be
  # pointed at a fleet its payer has nothing to do with.
  #
  # Checked only while the nomination or the link is being changed. A supporter
  # who later leaves the fleet leaves a stale nomination behind, and that must
  # not make every subsequent write to the row fail -- reconciliation is where a
  # nomination that stopped qualifying gets answered, not validation.
  private def nominated_fleet_is_the_payers_own
    return if fleet_id.blank?
    return unless will_save_change_to_fleet_id? || will_save_change_to_user_id?

    if user_id.blank?
      errors.add(:fleet, :requires_a_linked_supporter)
      return
    end

    return if user.fleet_memberships.kept.accepted.exists?(fleet_id:)

    errors.add(:fleet, :not_a_fleet_of_the_supporter)
  end

  private def ended_at_after_started_at
    return if ended_at.blank? || started_at.blank?
    return if ended_at >= started_at

    errors.add(:ended_at, :must_be_after_started_at)
  end

  private def force_anonymous_when_name_blank
    self.anonymous = true if name.blank? && user_id.blank?
  end
end
