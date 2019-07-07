# frozen_string_literal: true

class AddHangarFieldsToModels < ActiveRecord::Migration[5.2]
  def change
    add_column :docks, :model_id, :uuid
  end
end
