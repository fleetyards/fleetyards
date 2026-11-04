# frozen_string_literal: true

class MeasureFleetchartTopViews < ActiveRecord::Migration[8.1]
  def up
    ActiveStorage::Attachment
      .where(record_type: "Model", name: FleetchartTopViewAnalyzer::TOP_VIEW_NAMES)
      .includes(:blob)
      .find_each { |attachment| attachment.blob.analyze_later }
  end

  def down
  end
end
