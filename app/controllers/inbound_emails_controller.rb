# frozen_string_literal: true

class InboundEmailsController < Griddler::EmailsController
  http_basic_authenticate_with(
    name: Rails.application.credentials.postmark_inbound_basic_auth_user || "",
    password: Rails.application.credentials.postmark_inbound_basic_auth_password || "",
    if: -> { Rails.application.credentials.postmark_inbound_basic_auth_password.present? }
  )
end
