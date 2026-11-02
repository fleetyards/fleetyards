# frozen_string_literal: true

# Entries from before the key existed carry none, so a later entry from the
# same inbox would not be refused. The earliest entry of each inbox gets the
# key; the draw passes over the others either way.
class BackfillRaffleEntryEmailKeys < ActiveRecord::Migration[8.1]
  def up
    Raffle.where(concluded_at: nil).find_each do |raffle|
      seen = Set.new
      raffle.entries.includes(:user).where(email_key: nil).order(:created_at).each do |entry|
        key = RaffleEntry.email_key_for(entry.user&.email || entry.email)
        next if key.nil? || !seen.add?(key)

        entry.update_columns(email_key: key)
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
