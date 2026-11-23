# frozen_string_literal: true

# Folds a duplicate paint into the one kept for its ship: owners, pictures,
# plan candidates, pledge links, prices and whatever images or store data only
# the duplicate has move over, then the duplicate goes.
class ModelPaintMerger
  # Filled in on the kept paint only where it has none of its own.
  CARRIED_OVER = %i[
    component_id rsi_id rsi_name rsi_slug rsi_description rsi_store_url
    description store_url pledge_price production_status production_note
    last_updated_at store_images_updated_at
  ].freeze

  def initialize(kept, duplicate)
    raise ArgumentError, "paints of different ships" if kept.model_id != duplicate.model_id

    @kept = kept
    @duplicate = duplicate
  end

  # The ids of the ships whose cached payload names the duplicate.
  def run
    vehicle_ids = affected_vehicle_ids

    ModelPaint.transaction do
      move_owners
      @duplicate.picture_vehicles.update_all(picture_id: @kept.id)
      HangarPlanCandidate.where(model_paint_id: @duplicate.id).update_all(model_paint_id: @kept.id)
      move_pledge_links
      ItemPrice.where(item: @duplicate).update_all(item_id: @kept.id)
      move_attachments

      carried = CARRIED_OVER.select { |attribute| @kept[attribute].blank? && @duplicate[attribute].present? }
        .index_with { |attribute| @duplicate[attribute] }

      @duplicate.reload.destroy!
      @kept.update!(carried)
    end

    vehicle_ids
  end

  private def affected_vehicle_ids
    Vehicle.where(id: VehiclePaint.where(model_paint_id: @duplicate.id).select(:vehicle_id))
      .or(Vehicle.where(picture_type: "ModelPaint", picture_id: @duplicate.id))
      .ids
  end

  private def move_owners
    owners = VehiclePaint.where(model_paint_id: @kept.id).select(:vehicle_id)
    VehiclePaint.where(model_paint_id: @duplicate.id, vehicle_id: owners).delete_all
    VehiclePaint.where(model_paint_id: @duplicate.id).update_all(model_paint_id: @kept.id)
  end

  private def move_pledge_links
    linked = HangarPledgeItemModelPaint.where(model_paint_id: @kept.id).select(:hangar_pledge_item_id)
    HangarPledgeItemModelPaint.where(model_paint_id: @duplicate.id, hangar_pledge_item_id: linked).delete_all
    HangarPledgeItemModelPaint.where(model_paint_id: @duplicate.id).update_all(model_paint_id: @kept.id)
  end

  private def move_attachments
    attached = ActiveStorage::Attachment.where(record: @kept).select(:name)
    ActiveStorage::Attachment.where(record: @duplicate).where.not(name: attached).update_all(record_id: @kept.id)
  end
end
