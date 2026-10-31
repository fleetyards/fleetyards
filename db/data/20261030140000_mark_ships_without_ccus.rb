# frozen_string_literal: true

# RSI sells no upgrade into these ships. Most of them no hangar or buy-back
# ever showed one for, but a one-off such as "Kraken to Kraken Privateer"
# would otherwise make a ship reachable from every start, so they are marked
# outright. An admin's own choice is left alone.
class MarkShipsWithoutCcus < ActiveRecord::Migration[8.1]
  SLUGS = %w[
    aegs-idris-p aegs-idris-m aegs-javelin drak-kraken drak-kraken-privateer anvl-odin orig-890-jump cnou-pioneer
  ].freeze

  def up
    Model.where(slug: SLUGS, ccu_override: nil).update_all(ccu_override: "none", updated_at: Time.current)
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
