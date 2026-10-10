# frozen_string_literal: true

# The types are gone from the enum, so their rows would read back as a nil type.
class RemoveHangarAndWishlistNotifications < ActiveRecord::Migration[8.1]
  TYPES = %w[hangar_create hangar_destroy wishlist_create wishlist_destroy].freeze

  def up
    %w[notifications notification_preferences].each do |table|
      loop do
        deleted = execute(<<~SQL.squish).cmd_tuples
          DELETE FROM #{table} WHERE id IN (
            SELECT id FROM #{table} WHERE notification_type IN (#{quoted_types}) LIMIT 10000
          )
        SQL
        break if deleted.zero?
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private def quoted_types
    TYPES.map { |type| connection.quote(type) }.join(", ")
  end
end
