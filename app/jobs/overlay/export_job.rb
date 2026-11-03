# frozen_string_literal: true

module Overlay
  # Rebuilds and publishes one channel's overlay export. Enqueued once a game
  # data load for that channel has finished, and nightly for every channel as a
  # fallback; a run over an unchanged catalogue hashes the same and uploads
  # nothing.
  #
  # One run per channel at a time: a nightly run and a load's run would
  # otherwise race on the manifest. A run that finds the lock taken goes back on
  # the queue rather than being dropped, since the run holding it may have read
  # the catalogue before the load that enqueued this one wrote it.
  class ExportJob < ::Loaders::BaseJob
    RETRY_IN = 5.minutes

    sidekiq_options retry: 3

    def perform(channel = nil)
      channels = channel.present? ? [channel.to_s] : ::Overlay::Export.channels

      channels.each do |name|
        lock = ActiveRecord::Base.with_advisory_lock_result("overlay_export_#{name}", timeout_seconds: 0) do
          result = ::Overlay::Export.new(name).build
          outcome = ::Overlay::Publisher.new(name).publish(result)

          Rails.logger.info("[#{self.class.name}] #{name}: #{outcome} #{result.file_name} (#{result.manifest[:count]} items)")
        end

        self.class.perform_in(RETRY_IN, name) unless lock.lock_was_acquired?
      end
    end
  end
end
