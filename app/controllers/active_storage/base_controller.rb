# frozen_string_literal: true

# The base class for all Active Storage controllers.
class ActiveStorage::BaseController < ActionController::Base
  # What the upload forms send. The bucket is public and serves an object with
  # the type it was declared with, so text/html or image/svg+xml would be a
  # page of the uploader's choosing on the storage host.
  USER_UPLOAD_CONTENT_TYPES = %w[
    image/jpeg image/jpg image/png image/gif image/webp
    application/json
  ].freeze

  # Brochures and holo models are only uploaded in the admin app. Windows has
  # no type for glTF, so a model can arrive blank or as octet-stream.
  ADMIN_UPLOAD_CONTENT_TYPES = [
    *USER_UPLOAD_CONTENT_TYPES,
    "application/pdf", "application/octet-stream", "model/gltf+json", "model/gltf-binary", ""
  ].freeze

  before_action :authenticate!, if: :should_authenticate?
  before_action :refuse_unlisted_content_type, if: :should_authenticate?

  include ActiveStorage::SetCurrent

  protect_from_forgery with: :null_session

  self.etag_with_template_digest = false

  def authenticate!
    return if warden.authenticate?(scope: :user)
    return if warden.authenticate?(scope: :admin_user)

    throw(:warden)
  end

  def refuse_unlisted_content_type
    content_type = params.dig(:blob, :content_type).to_s.strip.downcase
    allowed = warden.authenticate?(scope: :admin_user) ? ADMIN_UPLOAD_CONTENT_TYPES : USER_UPLOAD_CONTENT_TYPES
    return if allowed.include?(content_type)

    head :unprocessable_content
  end

  def should_authenticate?
    is_a?(::ActiveStorage::DirectUploadsController)
  end
end
