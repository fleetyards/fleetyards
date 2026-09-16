# frozen_string_literal: true

# Every row linked before `linked_via` existed carries no rule, and the column
# would read as "unknown" for the whole back catalogue on the day it ships.
#
# Only a rule that still resolves to the account the row is actually linked to
# is written -- the rest stay null. That is the honest answer for them: the
# inputs may have changed since, and guessing a rule that no longer explains the
# link is worse than saying nothing.
class BackfillSupporterContributionLinkRules < ActiveRecord::Migration[8.1]
  def up
    SupporterContribution.where.not(user_id: nil).where(linked_via: nil).find_each do |contribution|
      rule = rule_for(contribution)
      next if rule.nil?

      contribution.update_column(:linked_via, rule)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  # Supporters::Linker's precedence, applied to the link the row already has.
  private def rule_for(contribution)
    return "patreon_account" if patreon_account(contribution) == contribution.user_id
    return "claim_key" if by_claim_key(contribution) == contribution.user_id
    return "payer_email" if by_verified_email(contribution) == contribution.user_id

    nil
  end

  private def patreon_account(contribution)
    return if contribution.patreon_user_id.blank?

    User.joins(:omniauth_connections).find_by(
      omniauth_connections: {
        provider: OmniauthConnection.providers[:patreon],
        uid: contribution.patreon_user_id
      }
    )&.id
  end

  private def by_claim_key(contribution)
    User.find_by_claim_key(contribution.claim_key_for_linking)&.id
  end

  private def by_verified_email(contribution)
    email = contribution.payer_email.to_s.strip.downcase
    return if email.blank?

    User.confirmed.find_by(email: email)&.id
  end
end
