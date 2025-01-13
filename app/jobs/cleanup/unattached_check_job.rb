# frozen_string_literal: true

module Cleanup
  class UnattachedCheckJob < ::Cleanup::BaseJob
    def perform
      ActiveStorage::Blob.unattached
        .where(created_at: ..2.days.ago)
        .find_each(&:purge_later)
    end
  end
end
