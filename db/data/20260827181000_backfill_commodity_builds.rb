# frozen_string_literal: true

# Seeds a build row from what each commodity row already says, so the new table is
# populated before anything reads from it -- rather than staying empty until the
# next sc_data load.
#
# Rows whose version is nil are skipped: the export stopped naming them, or never
# did. The UEX importer creates commodities too, and those carry no version -- for
# them the column keeps answering, which is why the readers fall back at all.
class BackfillCommodityBuilds < ActiveRecord::Migration[8.1]
  # Its own copy on purpose: a migration has to keep running against the schema of
  # its own moment, not `CommodityBuild::FACTS` as that later becomes.
  FACTS = %i[name commodity_type description].freeze

  def up
    environment = ScData::Source.environment

    Commodity.where.not(version: nil).find_each do |commodity|
      # Keyed on the version the row itself carries, not just the environment: a
      # commodity whose build already exists must be updated in place rather than
      # have some other build's row repointed at it.
      build = commodity.builds.find_or_initialize_by(
        environment:, version: commodity.version
      )

      # Read off the row rather than through the reader, which resolves the build
      # first -- the very row being written here.
      build.update!(FACTS.index_with { |fact| commodity.read_attribute(fact) })
    end
  end

  def down
    CommodityBuild.delete_all
  end
end
