# frozen_string_literal: true

class AddVolumeDimensionsToEquipment < ActiveRecord::Migration[8.1]
  def change
    # Gear is measured in fractions of an SCU — a helmet is 0.0087 — so two
    # decimal places rounded every piece in the table to zero.
    change_column :equipment, :volume, :decimal, precision: 15, scale: 6

    add_column :equipment, :volume_dimensions, :jsonb
  end
end
