# frozen_string_literal: true

# Seeds a build row from what each component row already says, so the new table is
# populated before anything reads from it -- rather than staying empty until the
# next sc_data load.
#
# Rows whose version is nil are skipped: the export stopped naming them, so there
# is no build they describe.
class BackfillComponentBuilds < ActiveRecord::Migration[8.1]
  # Its own copy on purpose: a migration has to keep running against the schema of
  # its own moment, not `ComponentBuild::FACTS` as that later becomes.
  FACTS = %i[
    manufacturer_id name description size grade item_type item_class
    component_class component_type component_sub_type category type_data
    durability power_connection heat_connection ammunition
    inventory_consumption tracking_signal hidden
  ].freeze

  # Eight thousand components, so batched rather than one transaction.
  BATCH_SIZE = 500

  def up
    environment = ScData::Source.environment

    Component.where.not(version: nil).find_each(batch_size: BATCH_SIZE) do |component|
      # Keyed on the version the row itself carries, not just the environment: a
      # component whose build already exists must be updated in place rather than
      # have some other build's row repointed at it.
      build = component.builds.find_or_initialize_by(
        environment:, version: component.version
      )

      build.update!(FACTS.index_with { |fact| component.public_send(fact) })
    end
  end

  def down
    ComponentBuild.delete_all
  end
end
