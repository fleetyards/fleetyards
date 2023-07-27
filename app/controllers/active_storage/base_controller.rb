# frozen_string_literal: true

# The base class for all Active Storage controllers.
class ActiveStorage::BaseController < ActionController::Base
  before_action :authenticate_user!, if: :should_authenticate?

  include ActiveStorage::SetCurrent

  protect_from_forgery with: :exception

  self.etag_with_template_digest = false

  def should_authenticate?
    is_a?(::ActiveStorage::DirectUploadsController)
  end
end
