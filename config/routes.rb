# frozen_string_literal: true

require "sidekiq/web"

Rails.application.default_url_options = {host: Rails.configuration.app.domain, trailing_slash: true}

Rails.application.routes.draw do
  devise_for :users, singular: :user, only: [:omniauth_callbacks], controllers: {
    omniauth_callbacks: "omniauth_callbacks"
  }

  draw :oauth_routes
  draw :docs_routes
  draw :api_routes
  draw :admin_routes
  draw :short_routes if Rails.configuration.app.short_domain.present?

  post "/emails/inbound" => "inbound_emails#create"

  # Discord's interactions endpoint. Deliberately outside :api_routes -- it is
  # not public API surface, carries no OpenAPI component and must not enter the
  # generated schema or the TS client.
  post "/discord/interactions" => "discord/interactions#create"
  post "/kofi/webhook" => "kofi/webhooks#create"

  if Rails.env.production?
    match "/uploads/(*path)", to: redirect { |_params, request| "#{Rails.configuration.app.legacy_cdn_endpoint}#{request.fullpath}" }, via: [:get, :head]
  end

  # Feed URLs were once handed out on the frontend host, and calendar clients
  # keep polling whatever URL they were given. Redirected rather than served so
  # the API host's throttle still applies.
  calendar_feed_redirect = redirect(status: 301) do |_params, req|
    path = req.path.delete_prefix("/v1").chomp("/")
    [API_ENDPOINT + path, req.query_string.presence].compact.join("?")
  end
  get "v1/fleets/:fleet_slug/events.ics", to: calendar_feed_redirect, format: false
  get "v1/me/calendar/events.ics", to: calendar_feed_redirect, format: false

  match "404" => "errors#not_found", :via => :all
  match "405" => "errors#method_not_allowed", :via => :all
  match "422" => "errors#unprocessable_entity", :via => :all
  match "406" => "errors#not_acceptable", :via => :all
  match "500" => "errors#server_error", :via => :all

  draw :frontend_routes
end
