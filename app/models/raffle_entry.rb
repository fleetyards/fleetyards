# frozen_string_literal: true

class RaffleEntry < ApplicationRecord
  paginates_per 50

  VERIFICATION_CODE_TTL = 30.minutes
  VERIFICATION_RESEND_INTERVAL = 2.minutes
  VERIFICATION_MAX_ATTEMPTS = 5

  has_paper_trail on: ::VersionedItem::RECORDED_EVENTS,
    skip: %i[email verification_code_digest verification_sent_at verification_attempts]

  encrypts :email

  belongs_to :raffle, inverse_of: :entries
  belongs_to :user, optional: true
  belongs_to :claimed_by, class_name: "AdminUser", optional: true

  attribute :conditions_accepted, :boolean, default: false

  validates :user_id, uniqueness: {scope: :raffle_id}, on: :create
  validates :conditions_accepted, acceptance: {accept: true}, on: :create
  validate :raffle_open, on: :create

  before_validation :snapshot_entrant, on: :create

  scope :won, -> { where.not(won_at: nil) }
  scope :pending_claim, -> { won.where(claimed_at: nil, forfeited_at: nil) }
  scope :claim_expired, ->(now = Time.current) { pending_claim.where(claim_deadline_at: ..now) }

  def display_username
    user&.username || username
  end

  def current_winner?
    won_at.present? && forfeited_at.nil?
  end

  def claimable?(now = Time.current)
    current_winner? && claimed_at.nil? && claim_deadline_at.present? && now < claim_deadline_at
  end

  def masked_email
    return if email.blank?

    local, domain = email.split("@", 2)
    host, _, tld = domain.to_s.rpartition(".")
    "#{local.first}***@#{host.first}***.#{tld}"
  end

  # The winner taking the code themselves, which is what claiming means: the
  # code is shown once the entry is marked claimed.
  def claim!(now = Time.current)
    claimed = with_lock do
      next false unless claimable?(now)

      update!(claimed_at: now)
    end
    raffle.conclude!(now) if claimed
    claimed
  end

  # A winner whose account is gone proves they are the entrant by reading back
  # a code sent to the address they entered with. Only a digest is stored; the
  # code itself exists in the mail and nowhere else.
  def issue_verification_code!(now = Time.current)
    return nil unless claimable?(now) && email.present?
    return nil if verification_sent_at.present? && now < verification_sent_at + VERIFICATION_RESEND_INTERVAL

    code = format("%06d", SecureRandom.random_number(1_000_000))
    update!(
      verification_code_digest: digest_verification_code(code),
      verification_sent_at: now,
      verification_attempts: 0
    )
    code
  end

  def verify_and_claim!(code, admin_user:, now: Time.current)
    result = with_lock { verification_result(code, admin_user:, now:) }
    raffle.conclude!(now) if result == :claimed
    result
  end

  private def verification_result(code, admin_user:, now:)
    return :not_claimable unless claimable?(now)
    return :no_code if verification_code_digest.blank?
    return :expired if now >= verification_sent_at + VERIFICATION_CODE_TTL
    return :too_many_attempts if verification_attempts >= VERIFICATION_MAX_ATTEMPTS

    unless ActiveSupport::SecurityUtils.secure_compare(verification_code_digest, digest_verification_code(code.to_s.strip))
      increment!(:verification_attempts)
      return :invalid
    end

    update!(claimed_at: now, claimed_by: admin_user, verification_code_digest: nil)
    :claimed
  end

  private def digest_verification_code(code)
    OpenSSL::HMAC.hexdigest("SHA256", Rails.application.secret_key_base, "raffle-entry:#{id}:#{code}")
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
