# frozen_string_literal: true

class FleetRsiVerificationJob < ::ApplicationJob
  sidekiq_options queue: "default"

  def perform(fleet_id, generation = nil)
    fleet = Fleet.kept.find_by(id: fleet_id)
    return if fleet.blank?

    generation ||= FleetRsiVerification.generation_of(fleet.rsi_verification_checked_at)

    FleetRsiVerification.new(fleet, generation:).run
  rescue => e
    Appsignal.report_error(e)

    FleetRsiVerification.fail_if_current!(fleet, generation) if fleet.present?
  end
end
