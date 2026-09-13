# frozen_string_literal: true

# `MeasureHoloJob` writes `length` / `beam` / `height` straight through
# `update_columns` and leaves no trace, so nothing downstream can tell a figure
# measured off a mesh from one somebody typed in.
#
# The metrics page needs that distinction: it offers the game-file figure as a
# correction, and a `maxBoundingBoxSize` is the worse number of the two once a
# holo has been measured -- its axes are not consistently oriented and no source
# says which configuration it was taken in.
#
# Attachment presence cannot stand in for this. The job refuses an export whose
# rotation is off the axes, and skips a value corrected while the file was being
# fetched; in both cases a holo is attached and the columns are not its work.
#
# Only the flying set gets a stamp, because only it has an `sc_*` counterpart to
# be compared against.
class AddDimensionsMeasuredAtToModels < ActiveRecord::Migration[8.1]
  def change
    add_column :models, :dimensions_measured_at, :datetime
  end
end
