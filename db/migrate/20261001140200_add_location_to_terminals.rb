# frozen_string_literal: true

# The place a terminal is at, matched by name during the UEX sync.
class AddLocationToTerminals < ActiveRecord::Migration[8.1]
  def change
    add_reference :terminals, :location, type: :uuid, foreign_key: {on_delete: :nullify}
  end
end
