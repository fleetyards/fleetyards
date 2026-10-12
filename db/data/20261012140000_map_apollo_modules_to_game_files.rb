# frozen_string_literal: true

# The Apollo's six medical-bed modules came from the ship matrix without an
# `sc_key`, and the modules loader only loads a module that has one, so the game
# files' names and descriptions never reached them. The keys are the item records
# the export ships them as; the next load fills in their builds.
class MapApolloModulesToGameFiles < ActiveRecord::Migration[8.1]
  SC_KEYS = (1..3).flat_map { |tier|
    %w[Left Right].map { |side| ["Tier #{tier} Module #{side}", "RSI_Apollo_Module_#{side}_Tier_#{tier}"] }
  }.to_h.freeze

  def up
    SC_KEYS.each do |name, sc_key|
      ModelModule.where(name:, sc_key: nil)
        .where(id: ModelModule.joins(:models).where("models.slug LIKE ?", "rsi-apollo-%").select(:id))
        .update_all(sc_key:, updated_at: Time.current)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
