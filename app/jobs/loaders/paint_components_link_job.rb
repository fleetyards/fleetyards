# frozen_string_literal: true

module Loaders
  # Runs after either side of the link changes: a paints import adds
  # ModelPaints, an sc_data load adds paint components.
  #
  # One run at a time, since a live and a ptu load can finish together and both
  # would copy the same artwork. A job that finds the lock taken goes back on
  # the queue rather than being dropped: the run holding it may have read the
  # components before this job's load wrote them.
  class PaintComponentsLinkJob < ::Loaders::BaseJob
    LOCK = "paint_components_link"
    RETRY_IN = 5.minutes

    def perform
      result = ActiveRecord::Base.with_advisory_lock_result(LOCK, timeout_seconds: 0) do
        ::PaintComponentLinker.new.run
      end

      self.class.perform_in(RETRY_IN) unless result.lock_was_acquired?
    end
  end
end
