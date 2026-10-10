# frozen_string_literal: true

class HangarSyncJob < ::ApplicationJob
  sidekiq_options queue: "default"

  def perform(import_id)
    import = Imports::HangarSync.find(import_id)
    data = import.input.map(&:deep_symbolize_keys)

    sync = HangarSync.new(data)
    sync.run_with_import(import)
  end
end
