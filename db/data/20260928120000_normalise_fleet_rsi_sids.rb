# frozen_string_literal: true

# Before the column was checked a fleet could save anything as its SID. The
# org's URL and a padded or bracketed SID are reduced to the SID; the rest --
# citizen handles, citizen record numbers, org names, once an email address --
# names no org, and some of it is personal data in a field the public API
# serves, so it is cleared.
class NormaliseFleetRsiSids < ActiveRecord::Migration[8.1]
  def up
    Fleet.unscoped.where.not(rsi_sid: nil).pluck(:id, :rsi_sid).each do |id, raw|
      sid = Rsi::Sid.normalize(raw)
      sid = nil unless Rsi::Sid.valid?(sid)
      next if sid == raw

      # rubocop:disable Rails/SkipsModelValidations
      Fleet.unscoped.where(id:).update_all(rsi_sid: sid, updated_at: Time.current)
      # rubocop:enable Rails/SkipsModelValidations
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
