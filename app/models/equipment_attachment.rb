# frozen_string_literal: true

# An attachment that fits one port of a weapon, as one build of the game states
# it. The loader matches each port's subtypes, size range and tags against every
# attachment, the way the game decides what a player can fit.
class EquipmentAttachment < ApplicationRecord
  belongs_to :build, class_name: "EquipmentBuild", inverse_of: :attachments,
    foreign_key: :equipment_build_id
  belongs_to :attachment, class_name: "Equipment", inverse_of: :attachment_fits
end
