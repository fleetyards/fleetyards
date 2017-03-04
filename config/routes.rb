# frozen_string_literal: true
require 'sidekiq/web'

Fleetyards::Application.routes.draw do
  concern :paginatable do
    get '(page/:page)', action: :index, on: :collection, as: ''
  end

  devise_for :users, skip: [:session, :omniauth_callbacks, :unlock, :confirmation, :password, :registration], controllers: {
    omniauth_callbacks: "users/omniauth_callbacks",
  }

  devise_for :users, skip: [:sessions, :registration], controllers: {
    registrations: "registrations"
  }

  draw :api_routes
  draw :backend_routes
  draw :frontend_routes

  root to: 'base#index'
end
