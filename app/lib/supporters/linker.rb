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

      user, rule = resolve
      return if user.nil?

      # The rule goes down with the link, in the same write. Recomputing it
      # later would be guesswork: a donor who put their key in the message and
      # paid from their registered address matches two arms, and by then there
      # is nothing left to say which one actually decided it.
      #
      # The supporter's standing choice of fleet goes down with it, which is the
      # only moment it can: a donation is imported and matched days after it was
      # made, and asking somebody to come back afterwards to say what it was for
      # is how a nomination never gets made at all. An answer already on the
      # contribution wins -- an admin who set one was looking at this payment.
      @contribution.update!(
        user: user,
        linked_via: rule,
        fleet_id: @contribution.fleet_id || supported_fleet_id_for(user)
      )
      user
    end

    # Only while they are still in the fleet. A standing choice outlives the
    # membership that justified it, and stamping a fleet somebody has left
    # would write an entitlement they cannot answer for.
    private def supported_fleet_id_for(user)
      fleet_id = user.effective_supported_fleet_id
      return if fleet_id.blank?
      return unless user.fleet_memberships.kept.accepted.exists?(fleet_id:)

      fleet_id
    end

    # The user and the name of the arm that found them, in precedence order.
    private def resolve
      if (user = by_connected_patreon_account)
        [user, :patreon_account]
      elsif (user = by_claim_key)
        [user, :claim_key]
      elsif (user = by_verified_email)
        [user, :payer_email]
      end
    end

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

    # A deliberate act, so it outranks the address: a supporter who put their key
    # in a donation meant that account, even if the payment carries an address
    # belonging to someone else's.
    private def by_claim_key
      User.find_by_claim_key(@contribution.claim_key_for_linking)
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
