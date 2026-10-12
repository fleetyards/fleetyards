# frozen_string_literal: true

# A paint pledge resolved to the catalogue paint it is. One pledge can be several
# -- a series paint like "100 Series IceBreak" is a paint on the 100i, the 125a
# and the 135c each. Both sides cascade in the database, so the link needs no
# callbacks of its own.
class HangarPledgeItemModelPaint < ApplicationRecord
  belongs_to :hangar_pledge_item
  belongs_to :model_paint
end
