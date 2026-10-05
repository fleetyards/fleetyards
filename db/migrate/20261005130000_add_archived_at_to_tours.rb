# frozen_string_literal: true

class AddArchivedAtToTours < ActiveRecord::Migration[8.1]
  def change
    add_column :tours, :archived_at, :datetime
  end
end
