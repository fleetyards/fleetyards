# frozen_string_literal: true

require 'rsi_roadmap_loader'

class RoadmapWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, queue: (ENV['ROADMAP_LOADER_QUEUE'] || 'fleetyards_roadmap_loader').to_sym

  def perform
    count_before = Audited::Audit.where(auditable_type: 'RoadmapItem').count

    RsiRoadmapLoader.new.fetch

    count_after = Audited::Audit.where(auditable_type: 'RoadmapItem').count

    changes = count_after - count_before

    return if changes.zero?

    RoadmapMailer.notify_admin(changes).deliver_later

    ActionCable.server.broadcast('roadmap', {
      changes: changes
    }.to_json)
  end
end
