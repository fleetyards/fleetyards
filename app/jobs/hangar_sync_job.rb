# frozen_string_literal: true

class HangarSyncJob < ::ApplicationJob
  sidekiq_options queue: "default"

  def perform(import_id)
    import = Imports::HangarSync.find(import_id)
    input = import.input
    input = JSON.parse(input) if input.is_a?(String)
    data = input.map(&:deep_symbolize_keys)

    sync = HangarSync.new(data)
    sync.run_with_import(import)
  end
end
