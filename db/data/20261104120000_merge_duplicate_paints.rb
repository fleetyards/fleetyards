# frozen_string_literal: true

# Two spellings left ships with the same paint twice. RSI sells a skin as both
# "Nomad - IceBreak Paint" and "Nomad IceBreak Livery", and the importer filed the
# second under "Ice Break"; "IceBreak" is how RSI and the game files spell it. And
# rows saved with stray whitespace in the name never matched the clean name the
# importer looked up, so it created a second row beside them.
class MergeDuplicatePaints < ActiveRecord::Migration[8.1]
  # Relinking rewrites every paint pledge's links, and a hangar sync writing the
  # same rows would wait on all of them until a wrapping transaction committed.
  disable_ddl_transaction!

  RENAMES = {"Ice Break" => "IceBreak"}.freeze
  WHITESPACE = " \t\r\n\u00A0"

  def up
    ModelPaint.transaction do
      refresh_vehicles(misnamed_paints.find_each.map { |paint| fix(paint) })
    end

    # A pledge resolves to a paint by its exact name, so it may now reach a paint
    # it could not before: the Caterpillar's and Mustang's IceBreak, for one.
    HangarPledgeItems::PaintLinker.new.link_all
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  # Raw SQL, because `normalizes` strips the value of a `where(name:)` as well.
  private def misnamed_paints
    ModelPaint.where("name <> btrim(name, ?)", WHITESPACE).or(ModelPaint.where(name: RENAMES.keys))
  end

  private def fix(paint)
    stripped = paint.name.squish
    name = RENAMES.fetch(stripped, stripped)
    other = ModelPaint.find_by(model_id: paint.model_id, name:)

    if other.blank?
      paint.update!(name:)
      return paint.id
    end

    # Admins hid the clean copy where the misnamed one was already in use. That one
    # holds the owners and the chosen image, and keeping the hidden copy would take
    # the paint out of the catalogue.
    kept, duplicate = (other.hidden && !paint.hidden) ? [paint, other] : [other, paint]
    merge(duplicate, kept, name)
    kept.id
  end

  private def merge(duplicate, kept, name)
    owners = VehiclePaint.where(model_paint_id: kept.id).select(:vehicle_id)
    VehiclePaint.where(model_paint_id: duplicate.id, vehicle_id: owners).delete_all
    VehiclePaint.where(model_paint_id: duplicate.id).update_all(model_paint_id: kept.id)

    duplicate.picture_vehicles.update_all(picture_id: kept.id)
    HangarPlanCandidate.where(model_paint_id: duplicate.id).update_all(model_paint_id: kept.id)

    attached = ActiveStorage::Attachment.where(record: kept).select(:name)
    ActiveStorage::Attachment.where(record: duplicate).where.not(name: attached).update_all(record_id: kept.id)

    component_id = kept.component_id || duplicate.component_id

    duplicate.destroy!
    kept.update!(name:, component_id:, updated_at: Time.current)
  end

  private def refresh_vehicles(paint_ids)
    vehicle_ids = Vehicle.where(id: VehiclePaint.where(model_paint_id: paint_ids).select(:vehicle_id))
      .or(Vehicle.where(picture_type: "ModelPaint", picture_id: paint_ids))
      .ids

    Vehicle.where(id: vehicle_ids).update_all(updated_at: Time.current)
    Vehicle.schedule_fleet_vehicle_updates(vehicle_ids)
  end
end
