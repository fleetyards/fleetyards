# frozen_string_literal: true

# Flight-ready ships the game files know take their cargo from their holds, but
# the rule only applies on save. This sets the ones still carrying the RSI
# page's figure, with its own copy of the rule so a later change to the model
# does not change what this did.
#
# The Javelin keeps the figure CIG named: the one in the game files is a
# temporary NPC version, not the ship that is sold.
#
# Written straight to the column rather than saved: a validation tripping on
# an unrelated attribute of one old model must not stop the deploy. `updated_at`
# moves with it so the cached ship payloads let the new figure through.
class RecomputeFlightReadyCargo < ActiveRecord::Migration[8.1]
  def up
    Model.where(slug: "aegs-javelin").update_all(keep_cargo: true, updated_at: Time.current)

    source = ::ScData::Source.default.served

    Model.where(production_status: "flight-ready", keep_cargo: false).find_each do |model|
      build = ModelBuild.find_by(model_id: model.id, environment: source.environment, version: source.version)
      next if build.blank?

      capacity = (build.cargo_holds || []).sum { |hold| hold["capacity"].to_f }
      next if model.cargo.present? && (model.cargo.to_f - capacity).abs < 0.001

      model.update_columns(cargo: capacity, updated_at: Time.current)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
