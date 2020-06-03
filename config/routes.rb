# frozen_string_literal: true

require 'sidekiq/web'

Rails.application.routes.draw do
  draw :api_routes
  draw :admin_routes
  draw :frontend_routes

  match '404' => 'errors#not_found', via: :all
  match '405' => 'errors#server_error', via: :all
  match '422' => 'errors#server_error', via: :all
  match '500' => 'errors#server_error', via: :all
end
