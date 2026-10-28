# frozen_string_literal: true

class RaffleEntry < ApplicationRecord
  paginates_per 50

  # What Postmark reports for a raffle mail, from its message events. `sent`
  # is ours: the mail left for Postmark and nothing has come back yet.
  MAIL_STATUSES = %w[sent delivered bounced].freeze

  # What an entry came to, from the entrant's side.
  OUTCOMES = %w[open waiting won claimed forfeited not_won].freeze

  has_paper_trail on: ::VersionedItem::RECORDED_EVENTS, skip: %i[email]

  encrypts :email

  belongs_to :raffle, inverse_of: :entries
  belongs_to :user, optional: true

  attribute :conditions_accepted, :boolean, default: false

  # The claim link in the winner's mail. Tied to `won_at`, so the link only
  # ever answers for the win it was sent for.
  generates_token_for :raffle_claim do
    won_at&.to_i
  end

  validates :user_id, uniqueness: {scope: :raffle_id}, on: :create
  validates :conditions_accepted, acceptance: {accept: true}, on: :create
  validates :claim_mail_status, :prize_mail_status, inclusion: {in: MAIL_STATUSES}, allow_nil: true
  validate :raffle_open, on: :create

  before_validation :snapshot_entrant, on: :create

  scope :won, -> { where.not(won_at: nil) }
  scope :pending_claim, -> { won.where(claimed_at: nil, forfeited_at: nil) }
  scope :claim_expired, ->(now = Time.current) { pending_claim.where(claim_deadline_at: ..now) }
  scope :mail_status_pending, -> {
    where(claim_mail_status: "sent").where.not(claim_mail_message_id: nil)
      .or(where(prize_mail_status: "sent").where.not(prize_mail_message_id: nil))
  }

  def display_username
    user&.username || username
  end

  # The account's address while there is one -- it may have changed since the
  # entry -- and the one captured at entry once the account is gone.
  def recipient_email
    user&.email || email
  end

  def outcome(now = Time.current)
    return "claimed" if claimed_at.present?
    return "forfeited" if won_at.present? && forfeited_at.present?
    return "won" if current_winner?
    return "not_won" if raffle.drawn?

    raffle.open?(now) ? "open" : "waiting"
  end

  def current_winner?
    won_at.present? && forfeited_at.nil?
  end

  def claimable?(now = Time.current)
    current_winner? && claimed_at.nil? && claim_deadline_at.present? && now < claim_deadline_at
  end

  def masked_email
    address = recipient_email
    return if address.blank?

    local, domain = address.split("@", 2)
    host, _, tld = domain.to_s.rpartition(".")
    "#{local.first}***@#{host.first}***.#{tld}"
  end

  # The winner following the link in their claim mail. Returns whether this
  # click claimed the prize; a second click, or one after the deadline, does
  # not.
  def claim!(now = Time.current)
    with_lock do
      next false unless claimable?(now)

      update!(claimed_at: now)
    end
  end

  private def snapshot_entrant
    return if user.blank?

    self.email = user.email
    self.conditions_version = Raffle::CONDITIONS_VERSION
    self.conditions_accepted_at = Time.current if conditions_accepted
  end

  private def raffle_open
    return if raffle.blank? || raffle.open?

    errors.add(:raffle, :not_open)
  end
end
