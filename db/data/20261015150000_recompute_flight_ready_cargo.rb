# frozen_string_literal: true

# Flight-ready ships take their cargo from the game-file holds now, but the
# rule only applies on save. The ones still carrying the RSI page's figure --
# 14 locally, the Retaliator's 102 SCU among them -- are set here.
#
# Written straight to the column rather than saved: a validation tripping on
# an unrelated attribute of one old model must not stop the deploy. `updated_at`
# moves with it so the cached ship payloads let the new figure through.
class RecomputeFlightReadyCargo < ActiveRecord::Migration[8.1]
  def up
    Model.where(production_status: "flight-ready").find_each do |model|
      capacity = model.cargo_holds_capacity
      next if (model.cargo.to_f - capacity).abs < 0.001

      model.update_columns(cargo: capacity, updated_at: Time.current)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
