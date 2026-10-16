# frozen_string_literal: true

# What the last import from the ship-views bucket read: the digest of the ship's
# listing, and the MD5 of each render it attached. The attachment's own checksum
# cannot stand in for the latter, because cropping a padded view replaces the
# blob.
class AddShipViewImportsToModels < ActiveRecord::Migration[8.1]
  def change
    add_column :models, :ship_views_digest, :string
    add_column :models, :ship_view_md5s, :jsonb, default: {}, null: false
  end
end
