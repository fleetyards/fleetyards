# frozen_string_literal: true

class FleetRsiVerificationJob < ::ApplicationJob
  sidekiq_options queue: "default"

  def perform(fleet_id)
    fleet = Fleet.kept.find_by(id: fleet_id)
    return if fleet.blank?

    FleetRsiVerification.new(fleet).run
  rescue => e
    Appsignal.report_error(e)

    # Left at pending, the settings page would wait on a check that never ends.
    fleet&.update_columns(rsi_verification_status: :failed, updated_at: Time.current) # rubocop:disable Rails/SkipsModelValidations
  end
end
