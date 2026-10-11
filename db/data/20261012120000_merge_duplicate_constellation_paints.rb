# frozen_string_literal: true

# The Constellation's Invictus paints were imported under several source names
# over the years, so every variant carried two or three copies of Dark Green and
# of Invictus Blue and Gold. The names kept are the ones the hangar syncs use
# today; the vehicles painted with a copy move to the kept paint.
class MergeDuplicateConstellationPaints < ActiveRecord::Migration[8.1]
  MERGES = {
    "2950 Invictus Dark Green" => "Dark Green",
    "2950 Invictus Dark Green v" => "Dark Green",
    "2950 Invictus Blue and Gold" => "Invictus Blue and Gold"
  }.freeze

  def up
    moved_vehicle_ids = []

    Model.where("name LIKE 'Constellation%'").find_each do |model|
      MERGES.each do |duplicate_name, kept_name|
        duplicate = ModelPaint.find_by(model_id: model.id, name: duplicate_name)
        next if duplicate.blank?

        kept = ModelPaint.find_by(model_id: model.id, name: kept_name)
        if kept.blank?
          duplicate.update!(name: kept_name)
          next
        end

        vehicles = Vehicle.where(model_paint_id: duplicate.id)
        moved_vehicle_ids.concat(vehicles.ids)
        vehicles.update_all(model_paint_id: kept.id, updated_at: Time.current)

        duplicate.destroy!
      end
    end

    Vehicle.schedule_fleet_vehicle_updates(moved_vehicle_ids)
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
