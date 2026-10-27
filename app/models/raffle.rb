# frozen_string_literal: true

class Raffle < ApplicationRecord
  paginates_per 24

  # Bumped whenever the participation conditions change in meaning, so every
  # entry records which wording its user accepted.
  CONDITIONS_VERSION = "2026-10-27"

  # Where a winner who can no longer sign in reaches us. Kept here rather than
  # in the locale files so all seven languages name the same contact.
  CONTACTS = {
    discord_handle: "torlekmaru",
    discord_invite: "https://discord.gg/6EQKAsb"
  }.freeze

  STATUSES = %w[draft upcoming open closed drawn concluded].freeze

  DEFAULT_SORTING_PARAMS = "ends_at desc"
  ALLOWED_SORTING_PARAMS = [
    "title asc", "title desc",
    "startsAt asc", "startsAt desc",
    "endsAt asc", "endsAt desc",
    "createdAt asc", "createdAt desc"
  ]

  # The gift code stays out of the version history: the admin versions
  # endpoint would otherwise hand it out in plain text.
  has_paper_trail on: ::VersionedItem::RECORDED_EVENTS, skip: [:code]

  encrypts :code

  belongs_to :model, optional: true
  belongs_to :drawn_by, class_name: "AdminUser", optional: true

  has_many :entries, class_name: "RaffleEntry", dependent: :delete_all, inverse_of: :raffle
  has_many :won_entries, -> { won.order(:draw_position) }, class_name: "RaffleEntry", inverse_of: false

  validates :title, presence: true
  validates :starts_at, presence: true
  validates :ends_at, presence: true
  validates :claim_period_days, numericality: {only_integer: true, greater_than: 0}
  validates :code, presence: true, if: :published?
  validate :ends_at_after_starts_at
  validate :frozen_after_draw, on: :update

  before_destroy :keep_drawn_raffles, prepend: true

  scope :published, -> { where(published: true) }

  def self.ransackable_attributes(auth_object = nil)
    ["title", "published", "starts_at", "ends_at", "drawn_at", "created_at", "updated_at", "id"]
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end

  def status(now = Time.current)
    return "draft" unless published?
    return "concluded" if concluded_at.present?
    return "drawn" if drawn?
    return "upcoming" if now < starts_at
    return "open" if now < ends_at

    "closed"
  end

  def open?(now = Time.current)
    status(now) == "open"
  end

  def drawable?(now = Time.current)
    status(now) == "closed"
  end

  def drawn?
    drawn_at.present?
  end

  def concluded?
    concluded_at.present?
  end

  # From the preloaded winners on a list, a fresh query everywhere else: a
  # cached association would still name the winner a promotion just replaced.
  def current_winner
    return won_entries.find(&:current_winner?) if won_entries.loaded?

    entries.won.where(forfeited_at: nil).order(:draw_position).first
  end

  def masked_code
    return if code.blank?

    "#{"*" * [code.length - 4, 4].max}#{code.last(4)}"
  end

  # Ends the raffle for good: the code is in a winner's hands or nobody is left
  # to take it. The email snapshots existed only to verify a claim, so they go
  # with it.
  def conclude!(now = Time.current)
    update!(concluded_at: now)
    entries.update_all(email: nil, verification_code_digest: nil, verification_sent_at: nil, updated_at: now)
  end

  # A drawn raffle is the public record of who entered and who won.
  private def keep_drawn_raffles
    return unless drawn?

    errors.add(:base, :drawn)
    throw :abort
  end

  private def ends_at_after_starts_at
    return if ends_at.blank? || starts_at.blank?
    return if ends_at > starts_at

    errors.add(:ends_at, :invalid)
  end

  # Entrants accepted the raffle as it stood when they entered; once the order
  # is drawn, nothing that decided it may change.
  private def frozen_after_draw
    return unless drawn_at_was.present?

    %w[code starts_at ends_at published].each do |attribute|
      errors.add(attribute, :frozen_after_draw) if will_save_change_to_attribute?(attribute)
    end
  end
end
