# frozen_string_literal: true

class RenameActiveStorageAttachmentNames < ActiveRecord::Migration[8.0]
  def up
    execute <<~SQL
      UPDATE active_storage_attachments
      SET name = regexp_replace(name, '^new_', '')
      WHERE name LIKE 'new_%'
    SQL
  end

  def down
    execute <<~SQL
      UPDATE active_storage_attachments
      SET name = 'new_' || name
      WHERE record_type IN (
        'Model', 'ModelPaint', 'ModelModule', 'ModelModulePackage',
        'ModelUpgrade', 'Component', 'Manufacturer', 'User', 'Fleet', 'Import'
      )
      AND name NOT IN ('file', 'image', 'preview_image')
    SQL
  end
end
