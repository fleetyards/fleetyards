# frozen_string_literal: true

class AddComponentToModelPaints < ActiveRecord::Migration[8.1]
  def change
    # Nullable on purpose, and the null carries meaning: FleetYards knows about
    # paints before the game does, so a paint RSI sells ahead of a build has no
    # component to point at yet. Nullified rather than cascaded, because losing
    # the component must not take the paint with it.
    add_reference :model_paints, :component,
      null: true, type: :uuid, foreign_key: {on_delete: :nullify}
  end
end
