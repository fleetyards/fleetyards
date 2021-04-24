# frozen_string_literal: true

require 'rsi/progress_tracker_loader'
require 'discord/progress_tracker_update'

module Loaders
  class ProgressTrackerJob < ::Loaders::BaseJob
    def perform
      count_before = PaperTrail::Version.where(item_type: 'ProgressTrackerItem').count

      ::Rsi::ProgressTrackerLoader.new.run

      changes = PaperTrail::Version.where(item_type: 'ProgressTrackerItem').count - count_before

      return if changes.zero?

      ProgressTrackerMailer.notify_admin(changes).deliver_later

      Discord::ProgressTrackerUpdate.new(changes: changes).run

      ActionCable.server.broadcast('progress_tracker', {
        changes: changes
      }.to_json)
    end
  end
end
