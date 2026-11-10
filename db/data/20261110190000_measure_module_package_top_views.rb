# frozen_string_literal: true

class MeasureModulePackageTopViews < ActiveRecord::Migration[8.1]
  def up
    ActiveStorage::Attachment
      .where(record_type: "ModelModulePackage", name: "top_view")
      .includes(:blob)
      .find_each { |attachment| attachment.blob.analyze_later }
  end

  def down
  end
end
