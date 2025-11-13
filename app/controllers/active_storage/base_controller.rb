# frozen_string_literal: true

# The base class for all Active Storage controllers.
class ActiveStorage::BaseController < ActionController::Base
  before_action :authenticate!, if: :should_authenticate?

  include ActiveStorage::SetCurrent

  protect_from_forgery with: :exception

  self.etag_with_template_digest = false

  def authenticate!
    return if warden.authenticate?(scope: :user)
    return if warden.authenticate?(scope: :admin_user)

    throw(:warden)
  end

  def should_authenticate?
    is_a?(::ActiveStorage::DirectUploadsController)
  end
end
