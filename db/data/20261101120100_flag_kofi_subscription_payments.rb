# frozen_string_literal: true

# Ko-fi payments recorded before the importer kept the subscription flag carry
# none. A payer whose payments arrive about a month apart is a subscriber, and
# without the flag the coverage reminder would ask them to switch to the
# monthly donation they already make. A subscriber with a single payment so
# far cannot be recognised and is left as it is.
class FlagKofiSubscriptionPayments < ActiveRecord::Migration[8.1]
  MONTHLY_GAP_DAYS = 26..35

  def up
    rows = SupporterContribution
      .where(source: "kofi", recurring: false, kofi_subscription: false)
      .pluck(:id, :user_id, :payer_email, :started_at)

    # Paired by account and by email separately: a payment the linker matched
    # to an account and one it did not can still come from the same payer.
    ids = [
      rows.group_by { |_, user_id, _, _| user_id },
      rows.group_by { |_, _, payer_email, _| payer_email&.downcase }
    ].flat_map do |by_payer|
      by_payer.except(nil).flat_map { |_, payments| monthly_ids(payments.sort_by(&:last)) }
    end

    SupporterContribution.where(id: ids).update_all(kofi_subscription: true)
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  # Every pair, not only neighbours: a gift between two renewals would
  # otherwise hide the month between them.
  private def monthly_ids(payments)
    payments.combination(2).flat_map do |(earlier_id, *, earlier_on), (later_id, *, later_on)|
      MONTHLY_GAP_DAYS.cover?((later_on - earlier_on).to_i.abs) ? [earlier_id, later_id] : []
    end.uniq
  end
end
