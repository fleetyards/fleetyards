# frozen_string_literal: true

# A ship's side view is the one from port, now that the starboard view sits
# beside it.
class RenameSideViewsToPortViews < ActiveRecord::Migration[8.1]
  NAMES = {
    "Model" => %w[
      side_view side_view_colored
      extended_side_view extended_side_view_colored
      landed_side_view landed_side_view_colored
    ],
    "ModelPaint" => %w[side_view],
    "ModelModulePackage" => %w[side_view]
  }.freeze

  def up
    rename(from: "side_view", to: "port_view")
  end

  def down
    rename(from: "port_view", to: "side_view")
  end

  private

  def rename(from:, to:)
    NAMES.each do |record_type, names|
      names.each do |name|
        old_name = name.sub("side_view", from)
        new_name = name.sub("side_view", to)

        execute <<~SQL.squish
          UPDATE active_storage_attachments
          SET name = #{quote(new_name)}
          WHERE record_type = #{quote(record_type)} AND name = #{quote(old_name)}
        SQL

        next unless record_type == "Model"

        execute <<~SQL.squish
          UPDATE models
          SET pending_trims = (pending_trims - #{quote(old_name)})
            || jsonb_build_object(#{quote(new_name)}, pending_trims -> #{quote(old_name)})
          WHERE pending_trims ? #{quote(old_name)}
        SQL
      end
    end
  end

  def quote(value)
    connection.quote(value)
  end
end
