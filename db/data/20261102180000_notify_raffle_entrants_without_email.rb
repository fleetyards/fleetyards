# frozen_string_literal: true

# Accounts with only a placeholder address could enter raffles until they were
# made ineligible, and the draw now passes them over. Whoever already entered a
# raffle that is still open is told, so there is time to add a real address.
class NotifyRaffleEntrantsWithoutEmail < ActiveRecord::Migration[8.1]
  def up
    Raffle.running.find_each { |raffle| Raffles::EmailMissingNotice.new(raffle).call }
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
