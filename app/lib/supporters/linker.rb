# frozen_string_literal: true

module Supporters
  # Resolves which account a contribution belongs to, for every funding
  # platform, from two inputs the contribution already carries.
  #
  # Source-agnostic on purpose: Patreon supplies the email through its API,
  # Ko-fi through its webhook, and PayPal or Buy Me a Coffee through an admin
  # typing it in. All three produce the same input, so all three take the same
  # path rather than one resolver each.
  #
  # Idempotent, and safe to re-run over unlinked rows -- which is the point. A
  # donor whose email had no account when they paid is found when they register,
  # without anyone re-entering anything.
  class Linker
    def self.call(contribution)
      new(contribution).call
    end

    def initialize(contribution)
      @contribution = contribution
    end

    # Returns the linked user, or nil when nothing resolved. Never overwrites an
    # existing link: an admin who linked a row by hand outranks both rules.
    def call
      return @contribution.user if @contribution.user_id.present?

      user = by_connected_patreon_account || by_claim_key || by_verified_email
      return if user.nil?

      @contribution.update!(user: user)
      user
    end

    # First, because it is a deliberate act. A supporter who put their key in a
    # donation meant that account, even if the payment carries an address
    # belonging to someone else's.
    # First, because it is the only arm nobody asserts: the supporter proved
    # they hold the Patreon account by signing into it. A key can be mistyped
    # into the wrong payment and an address can be shared; this cannot.
    private def by_connected_patreon_account
      return if @contribution.patreon_user_id.blank?

      User.joins(:omniauth_connections).find_by(
        omniauth_connections: {
          provider: OmniauthConnection.providers[:patreon],
          uid: @contribution.patreon_user_id
        }
      )
    end

    private def by_claim_key
      User.find_by_claim_key(SupporterClaimKey.extract(@contribution.note))
    end

    # Safe where a user-entered address would not be: neither side is a claim.
    # The platform verified it for billing and we verified it at confirmation,
    # so this compares two independently verified records. An unconfirmed
    # account is not one of those and never matches.
    private def by_verified_email
      email = @contribution.payer_email.to_s.strip.downcase
      return if email.blank?

      User.confirmed.find_by(email: email)
    end
  end
end
