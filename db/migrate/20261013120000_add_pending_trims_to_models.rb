# frozen_string_literal: true

class AddPendingTrimsToModels < ActiveRecord::Migration[8.1]
  def change
    add_column :models, :pending_trims, :jsonb, default: {}, null: false
  end
end
