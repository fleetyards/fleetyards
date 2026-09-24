# frozen_string_literal: true

module FleetContracts
  # Closes the contracts whose deadline has passed while they were still on the
  # board or being worked.
  #
  # Expiring a contract moves no goods, exactly as cancelling one does not: a
  # delivery already accepted stays in the destination, and a transfer still in
  # flight resolves on its own -- a refused or timed-out one compensates back
  # into its source through `Inventories::TransferResolver`. What the expiry
  # does change is that no further transfer can be filed under the contract.
  class ExpireJob < ::ApplicationJob
    sidekiq_options queue: "default", retry: 3

    def perform
      ::FleetContract.active.where(deadline: ...Time.current).find_each do |contract|
        expire(contract)
      rescue => e
        Appsignal.report_error(e)
        Rails.logger.error("[FleetContracts::ExpireJob] #{contract.id}: #{e.class}: #{e.message}")
      end
    end

    # The row is locked and re-read before the transition, because the sweep
    # races the final delivery (`Contracts::Fulfilment` takes the same lock), a
    # manager cancelling, and a deadline being moved out. With
    # `whiny_transitions: false` the loser would otherwise fail silently.
    #
    # Validations are skipped on purpose: a contract whose destination inventory
    # has since been deleted no longer validates, and it must still close rather
    # than stay on the board forever.
    private def expire(contract)
      contract.with_lock do
        next unless contract.may_expire?
        next unless contract.deadline.present? && contract.deadline.past?

        contract.expire
        contract.save!(validate: false)
      end
    end
  end
end
