# frozen_string_literal: true

class AddHeadWearToEquipment < ActiveRecord::Migration[8.1]
  def change
    add_column :equipment, :head_wear, :jsonb
  end
end
