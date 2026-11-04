# frozen_string_literal: true

# Two spellings left ships with the same paint twice. RSI sells a skin as both
# "Nomad - IceBreak Paint" and "Nomad IceBreak Livery", and the importer filed the
# second under "Ice Break"; "IceBreak" is how RSI and the game files spell it. And
# rows saved with stray whitespace in the name never matched the clean name the
# importer looked up, so it created a second row beside them.
class MergeDuplicatePaints < ActiveRecord::Migration[8.1]
  RENAMES = {"Ice Break" => "IceBreak"}.freeze
  WHITESPACE = " \t\r\n"

  def up
    paint_ids = misnamed_paints.find_each.map do |paint|
      name = RENAMES.fetch(paint.name, paint.name.strip)
      kept = ModelPaint.find_by(model_id: paint.model_id, name:)

      if kept.present?
        merge(paint, kept)
        kept.id
      else
        paint.update!(name:)
        paint.id
      end
    end

    # A pledge resolves to a paint by its exact name, so it may now reach a paint
    # it could not before: the Caterpillar's and Mustang's IceBreak, for one.
    HangarPledgeItems::PaintLinker.new.link_all
    refresh_vehicles(paint_ids)
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  # Raw SQL, because `normalizes` strips the value of a `where(name:)` as well.
  private def misnamed_paints
    ModelPaint.where("name <> btrim(name, ?)", WHITESPACE).or(ModelPaint.where(name: RENAMES.keys))
  end

  private def merge(paint, kept)
    owners = VehiclePaint.where(model_paint_id: kept.id).select(:vehicle_id)
    VehiclePaint.where(model_paint_id: paint.id, vehicle_id: owners).delete_all
    VehiclePaint.where(model_paint_id: paint.id).update_all(model_paint_id: kept.id)

    paint.picture_vehicles.update_all(picture_id: kept.id)
    HangarPlanCandidate.where(model_paint_id: paint.id).update_all(model_paint_id: kept.id)

    attached = ActiveStorage::Attachment.where(record: kept).select(:name)
    ActiveStorage::Attachment.where(record: paint).where.not(name: attached).update_all(record_id: kept.id)

    component_id = kept.component_id || paint.component_id

    paint.destroy!
    kept.update!(component_id:)
  end

  private def refresh_vehicles(paint_ids)
    vehicle_ids = Vehicle.where(id: VehiclePaint.where(model_paint_id: paint_ids).select(:vehicle_id))
      .or(Vehicle.where(picture_type: "ModelPaint", picture_id: paint_ids))
      .ids

    Vehicle.where(id: vehicle_ids).update_all(updated_at: Time.current)
    Vehicle.schedule_fleet_vehicle_updates(vehicle_ids)
  end
end
