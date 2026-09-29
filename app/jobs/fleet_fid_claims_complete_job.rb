# frozen_string_literal: true

class FleetFidClaimsCompleteJob < ::ApplicationJob
  sidekiq_options queue: "default"

  def perform
    FleetFidClaim.complete_due!
  end
end
