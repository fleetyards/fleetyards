# frozen_string_literal: true

class ApplicationController < ActionController::Base
  http_basic_authenticate_with name: Rails.secrets.basic_auth_user,
                               password: Rails.secrets.basic_auth_password,
                               if: -> { Rails.secrets.basic_auth_password.present? }
end
