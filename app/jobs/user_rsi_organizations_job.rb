# frozen_string_literal: true

class UserRsiOrganizationsJob < ::ApplicationJob
  sidekiq_options queue: "default"

  def perform(user_id)
    user = User.find_by(id: user_id)
    return if user.blank?

    UserRsiOrganizations.new(user).run
  rescue => e
    Appsignal.report_error(e)
  end
end
