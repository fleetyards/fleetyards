# frozen_string_literal: true

# == Schema Information
#
# Table name: tours
#
#  id            :uuid             not null, primary key
#  archived_at   :datetime
#  cancelled_at  :datetime
#  currency      :string           default("auec"), not null
#  description   :text
#  invite_token  :string           not null
#  settled_at    :datetime
#  slug          :string           not null
#  starts_at     :datetime
#  status        :string           default("open"), not null
#  title         :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  created_by_id :uuid             not null
#  fleet_id      :uuid
#
# Indexes
#
#  index_tours_on_created_by_id_and_status  (created_by_id,status)
#  index_tours_on_fleet_id_and_status       (fleet_id,status)
#  index_tours_on_invite_token              (invite_token) UNIQUE
#  index_tours_on_slug                      (slug) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (created_by_id => users.id)
#  fk_rails_...  (fleet_id => fleets.id)
#
class Tour < ApplicationRecord
  include AASM

  paginates_per 30

  belongs_to :created_by, class_name: "User"

  # A fleet tour is organised from a fleet's page and answers to its payout
  # privileges; a tour with no fleet is the ad-hoc trip the standalone tool
  # exists for, and answers only to its own participant list.
  belongs_to :fleet, optional: true

  has_one :payout_ledger, as: :subject, dependent: :destroy

  # Only a fleet tour ever has any: a standalone tour is not listed anywhere a
  # stranger can see it, so the invite link is the only way onto one.
  has_many :join_requests, class_name: "TourJoinRequest", dependent: :destroy

  # Mostly a game run counted in aUEC, but some groups split real money too.
  # Only labels the ledger's figures -- nothing is ever converted.
  CURRENCIES = %w[auec usd eur gbp cad aud nzd chf sek nok dkk pln czk jpy cny twd brl mxn].freeze

  validates :title, presence: true
  validates :currency, inclusion: {in: CURRENCIES}
  validate :currency_fixed_once_settled, on: :update

  before_validation :ensure_id, on: :create
  before_validation :set_invite_token, on: :create
  before_save :update_slug
  before_destroy :ensure_deletable, prepend: true

  scope :active, -> { where(cancelled_at: nil) }
  scope :archived, -> { where.not(archived_at: nil) }
  scope :not_archived, -> { where(archived_at: nil) }
  scope :standalone, -> { where(fleet_id: nil) }

  DEFAULT_SORTING_PARAMS = ["created_at desc"]
  ALLOWED_SORTING_PARAMS = [
    "title asc", "title desc",
    "startsAt asc", "startsAt desc",
    "createdAt asc", "createdAt desc",
    "updatedAt asc", "updatedAt desc"
  ]

  aasm column: :status, timestamps: true, whiny_transitions: false do
    state :open, initial: true
    state :settled
    state :cancelled

    event :settle do
      transitions from: :open, to: :settled
    end

    event :reopen do
      transitions from: :settled, to: :open

      # aasm's `timestamps: true` only writes `#{state}_at` where the column
      # exists, and there is no `open_at` here -- so without this the tour goes
      # back to open still carrying the date it was settled on.
      after { update_column(:settled_at, nil) }
    end

    event :cancel do
      transitions from: [:open, :settled], to: :cancelled
    end
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[title slug status starts_at created_by_id fleet_id created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[created_by fleet payout_ledger]
  end

  def cancelled? = cancelled_at.present?

  def archived? = archived_at.present?

  def archive!
    update!(archived_at: Time.current) unless archived?
  end

  def unarchive!
    update!(archived_at: nil) if archived?
  end

  # The organiser is put on the ledger the moment a tour is created, so a tour
  # nobody else has joined and nothing was recorded on holds no one else's
  # money. Anything more is history somebody may still need, and is archived
  # instead.
  def deletable?
    ledger = payout_ledger
    return true if ledger.blank?

    ledger.payout_entries.none? &&
      ledger.payout_participants.where("user_id IS DISTINCT FROM ?", created_by_id).none?
  end

  def rotate_invite_token!
    update!(invite_token: self.class.generate_invite_token)
  end

  # The token is the whole credential -- TourPolicy#join? admits anyone holding
  # it -- and a guessed one buys a share of the profit, so this is deliberately
  # far longer than the 8 characters a fleet invite uses. It also removes the
  # birthday collision that the unique index would otherwise surface as an
  # unrescued RecordNotUnique.
  def self.generate_invite_token
    SecureRandom.hex(16)
  end

  # Tours share one slug namespace whether or not they belong to a fleet -- a
  # tour is addressed by slug alone -- so two people naming a trip "Jumptown
  # Run" would collide. The id prefix is what makes that impossible, the same
  # way FleetEvent does it within a fleet, and it reads as
  # `<short-id>-<title>` in the URL.
  # Only guards someone deleting the tour. An organiser deleting their account
  # takes their tours with them, and refusing would leave the account stuck.
  # The settled transfers are what people pay each other, and relabelling them
  # would change what they owe without converting anything.
  private def currency_fixed_once_settled
    return unless will_save_change_to_currency?
    return if open?

    errors.add(:currency, :fixed_once_settled)
  end

  private def ensure_deletable
    return if destroyed_by_association.present?
    return if deletable?

    errors.add(:base, :has_participants)
    throw :abort
  end

  private def update_slug
    base = generate_slug(title)
    prefix = id.to_s.split("-").first
    candidate = prefix.present? ? "#{prefix}-#{base}" : base
    return if slug == candidate

    self.slug = candidate
  end

  # The slug is built from the id, so it has to exist before the first save
  # rather than being handed out by the database default.
  private def ensure_id
    self.id ||= SecureRandom.uuid
  end

  private def set_invite_token
    self.invite_token ||= self.class.generate_invite_token
  end
end
