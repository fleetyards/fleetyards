# frozen_string_literal: true

# The ship matrix gives the Endeavor 200 m, but at that size the hangar module
# in the Master Set top view is about 20 m wide between its walls. The floor
# spans 341 px against 3,458 px of bare hull, so the 55 m wide Apollo it is
# meant to hold needs at least 558 m; 600 m leaves about 2 m either side. Every
# stored dimension scales by the same factor so the hull keeps its proportions.
class ScaleEndeavorToHoldAnApollo < ActiveRecord::Migration[8.1]
  SLUG = "misc-endeavor"
  PREVIOUS_LENGTH = 200
  LENGTH = 600

  COLUMNS = %w[
    length beam height
    fleetchart_offset_length fleetchart_offset_beam
    extended_length extended_beam extended_height
    extended_fleetchart_offset_length extended_fleetchart_offset_beam
    landed_length landed_beam landed_height
    landed_fleetchart_offset_length landed_fleetchart_offset_beam
  ].freeze

  def up
    factor = LENGTH.to_r / PREVIOUS_LENGTH
    assignments = COLUMNS.map { |column| "#{column} = ROUND(#{column} * #{factor.to_f}, 2)" }

    execute <<~SQL.squish
      UPDATE models
      SET #{assignments.join(", ")}, updated_at = NOW()
      WHERE slug = #{connection.quote(SLUG)} AND length = #{PREVIOUS_LENGTH}
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
