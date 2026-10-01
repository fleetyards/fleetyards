# frozen_string_literal: true

class AddSplitFromToFleetEvents < ActiveRecord::Migration[8.1]
  def change
    add_reference :fleet_events, :split_from, type: :uuid, null: true,
      foreign_key: {to_table: :fleet_events, on_delete: :nullify}
  end
end
