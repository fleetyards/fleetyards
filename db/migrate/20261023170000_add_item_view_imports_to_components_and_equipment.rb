# frozen_string_literal: true

# What the last import from the item-views bucket read: the digest of the
# item's listing, and the MD5 of each render it attached, so a view uploaded by
# hand over an imported render is not overwritten by the next run.
class AddItemViewImportsToComponentsAndEquipment < ActiveRecord::Migration[8.1]
  def change
    %i[components equipment].each do |table|
      add_column table, :item_views_digest, :string
      add_column table, :item_view_md5s, :jsonb, default: {}, null: false
    end
  end
end
