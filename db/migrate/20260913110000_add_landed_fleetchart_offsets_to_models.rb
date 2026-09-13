# frozen_string_literal: true

# The fleetchart draws a ship at the length it should occupy in a row, which is
# not always the length the hull measures: `fleetchart_offset_length` is the
# override, and `extended_*` carries its own pair for the deployed state.
#
# The landed state was given dimensions without them, so a landed figure that
# needs the same correction has nowhere to record it.
class AddLandedFleetchartOffsetsToModels < ActiveRecord::Migration[8.1]
  def change
    add_column :models, :landed_fleetchart_offset_length, :decimal, precision: 15, scale: 2
    add_column :models, :landed_fleetchart_offset_beam, :decimal, precision: 15, scale: 2
  end
end
