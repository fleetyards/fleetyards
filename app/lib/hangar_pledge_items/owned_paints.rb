# frozen_string_literal: true

module HangarPledgeItems
  # Which of the given catalogue paints a user owns: the ones their synced paint
  # pledges resolved to (`PaintLinker`).
  class OwnedPaints
    attr_reader :user

    def initialize(user)
      @user = user
    end

    def paint_ids(paints)
      HangarPledgeItemModelPaint
        .joins(:hangar_pledge_item)
        .where(hangar_pledge_items: {user_id: user.id})
        .where(model_paint_id: paints.map(&:id))
        .distinct
        .pluck(:model_paint_id)
    end
  end
end
