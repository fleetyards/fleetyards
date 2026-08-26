# frozen_string_literal: true

# Seeds a build row from what each equipment row already says, so the new table
# is populated before anything reads from it -- rather than staying empty until
# the next sc_data load.
#
# Rows whose version is nil are skipped: the export stopped naming them, so there
# is no build they describe.
class BackfillEquipmentBuilds < ActiveRecord::Migration[8.1]
  FACTS = %i[
    manufacturer_id name description equipment_type item_type sub_type
    weapon_class size grade slot hidden rate_of_fire range storage
    damage_reduction temperature_rating radiation_protection
    radiation_scrub_rate g_force_tolerance core_compatibility
    backpack_compatibility volume volume_dimensions
  ].freeze

  def up
    environment = ScData::Source.environment

    Equipment.where.not(version: nil).find_each do |equipment|
      build = equipment.builds.find_or_initialize_by(environment:)

      build.update!(FACTS.index_with { |fact| equipment.public_send(fact) }.merge(version: equipment.version))
    end
  end

  def down
    EquipmentBuild.delete_all
  end
end
