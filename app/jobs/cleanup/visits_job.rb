# frozen_string_literal: true

module Cleanup
  class VisitsJob < ::Cleanup::BaseJob
    def perform
      tracking_blocklist = User.where(tracking: false).pluck(:id)
      Ahoy::Visit.without_users(tracking_blocklist).rollup('Visits', interval: 'month', column: :started_at)

      Ahoy::Visit.where('started_at < ?', 1.month.ago).find_in_batches do |visits|
        visit_ids = visits.map(&:id)
        Ahoy::Event.where(visit_id: visit_ids).delete_all
        Ahoy::Visit.where(id: visit_ids).delete_all
      end
    end
  end
end
