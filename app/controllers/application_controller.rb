# frozen_string_literal: true

class ApplicationController < ActionController::Base
  http_basic_authenticate_with name: Rails.configuration.basic_auth.user,
                               password: Rails.configuration.basic_auth.password,
                               if: -> { Rails.configuration.basic_auth.password.present? }
end
