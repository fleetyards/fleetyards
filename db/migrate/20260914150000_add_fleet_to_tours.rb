# frozen_string_literal: true

class AddFleetToTours < ActiveRecord::Migration[8.1]
  def change
    # Nullable: a tour organised by an ad-hoc group belongs to no fleet, which
    # is the case the standalone tool exists for. A fleet only claims the ones
    # created from its own page.
    add_reference :tours, :fleet, type: :uuid, null: true, foreign_key: true, index: false

    add_index :tours, [:fleet_id, :status]
  end
end
