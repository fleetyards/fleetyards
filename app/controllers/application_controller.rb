# frozen_string_literal: true

class ApplicationController < ActionController::Base
  http_basic_authenticate_with name: Rails.configuration.x.basic_auth.user,
                               password: Rails.configuration.x.basic_auth.password,
                               if: -> { Rails.configuration.x.basic_auth.password.present? }
end
