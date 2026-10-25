# frozen_string_literal: true

require "test_helper"

# The frontend picker files a catalogue pick by its slices of the equipment
# table, and the backend files a hangar deposit by its own mapping. A piece the
# two file differently splits into two stock positions, and contract progress
# stops counting it, so the two are held to one answer here.
class InventoryEquipmentCategoriesTest < ActiveSupport::TestCase
  SOURCE = Rails.root.join("app/frontend/frontend/composables/useInventoryOptions.ts")

  # `inventoryCategoryForEquipment`: the first category whose slice holds the
  # type, in the order the object lists them.
  def frontend_categories
    block = SOURCE.read[/INVENTORY_EQUIPMENT_TYPES[^=]*= \{(.*?)\n\};/m, 1]

    block.scan(/^\s*(\w+): \[([^\]]*)\]/).each_with_object({}) do |(category, types), filed|
      types.scan(/"(\w+)"/).flatten.each { |type| filed[type] ||= category }
    end
  end

  test "files every equipment type under the category the picker files it under" do
    assert_equal frontend_categories, InventoryLedgerEntry::CATEGORIES_BY_EQUIPMENT_TYPE
  end

  test "maps every equipment type the catalogue knows" do
    assert_equal Equipment::EQUIPMENT_TYPES.sort, InventoryLedgerEntry::CATEGORIES_BY_EQUIPMENT_TYPE.keys.sort
  end
end
