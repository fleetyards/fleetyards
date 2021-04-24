# frozen_string_literal: true

require 'rsi/roadmap_loader'
require 'discord/roadmap_update'

module Loaders
  class RoadmapJob < ::Loaders::BaseJob
    def perform
      count_before = PaperTrail::Version.where(item_type: 'RoadmapItem').count

      ::Rsi::RoadmapLoader.new.fetch

      changes = PaperTrail::Version.where(item_type: 'RoadmapItem').count - count_before

      return if changes.zero?

      RoadmapMailer.notify_admin(changes).deliver_later

      Discord::RoadmapUpdate.new(changes: changes).run

      ActionCable.server.broadcast('roadmap', {
        changes: changes
      }.to_json)
    end
  end
end
