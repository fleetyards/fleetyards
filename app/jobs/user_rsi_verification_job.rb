# frozen_string_literal: true

class UserRsiVerificationJob < ::ApplicationJob
  sidekiq_options queue: "default"

  def perform(user_id, generation = nil)
    user = User.find_by(id: user_id)
    return if user.blank?

    generation ||= UserRsiVerification.generation_of(user.rsi_verification_checked_at)

    UserRsiVerification.new(user, generation:).run
  rescue => e
    Appsignal.report_error(e)

    UserRsiVerification.fail_if_current!(user, generation) if user.present?
  end
end
