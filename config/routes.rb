# frozen_string_literal: true

require 'sidekiq/web'

Rails.application.default_url_options = { host: Rails.configuration.app.domain, trailing_slash: true }

Rails.application.routes.draw do
  draw :api_routes
  draw :admin_routes
  draw :frontend_routes
  draw :short_routes if Rails.configuration.app.short_domain.present?

  match '404' => 'errors#not_found', via: :all
  match '405' => 'errors#method_not_allowed', via: :all
  match '422' => 'errors#unprocessable_entity', via: :all
  match '406' => 'errors#not_acceptable', via: :all
  match '500' => 'errors#server_error', via: :all
end
