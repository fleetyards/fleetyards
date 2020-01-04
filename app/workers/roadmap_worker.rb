# frozen_string_literal: true

require 'rsi/roadmap_loader'

class RoadmapWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, queue: (ENV['ROADMAP_LOADER_QUEUE'] || 'fleetyards_roadmap_loader').to_sym

  def perform
    count_before = PaperTrail::Version.where(item_type: 'RoadmapItem').count

    ::RSI::RoadmapLoader.new.fetch

    changes = PaperTrail::Version.where(item_type: 'RoadmapItem').count - count_before

    return if changes.zero?

    RoadmapMailer.notify_admin(changes).deliver_later

    ActionCable.server.broadcast('roadmap', {
      changes: changes
    }.to_json)
  end
end
