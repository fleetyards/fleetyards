# frozen_string_literal: true

require Rails.root.join("lib/fleetchart_top_view_analyzer").to_s

Rails.application.config.active_storage.analyzers = [
  FleetchartTopViewAnalyzer,
  *Rails.application.config.active_storage.analyzers
]
