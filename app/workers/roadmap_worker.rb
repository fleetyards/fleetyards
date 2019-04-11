# frozen_string_literal: true

require 'rsi_roadmap_loader'

class RoadmapWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, queue: (ENV['ROADMAP_LOADER_QUEUE'] || 'fleetyards_roadmap_loader').to_sym

  def perform
    count_before = Audited::Audit.where(auditable_type: 'RoadmapItem').count

    RsiRoadmapLoader.new.fetch

    count_after = Audited::Audit.where(auditable_type: 'RoadmapItem').count

    return if count_before == count_after

    ActionCable.server.broadcast('roadmap', {
      changes: count_after - count_before
    }.to_json)
  end
end
