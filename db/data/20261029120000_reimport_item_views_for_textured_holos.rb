# frozen_string_literal: true

# The item-views import skips an item whose listing is unchanged, and the
# textured holos published before items had a field for them were skipped with
# it. Clearing the digest makes the next run read every listing again; renders
# already attached are matched by their MD5 and not fetched.
class ReimportItemViewsForTexturedHolos < ActiveRecord::Migration[8.1]
  def up
    [Component, Equipment].each do |klass|
      klass.where.not(item_views_digest: nil).update_all(item_views_digest: nil)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
