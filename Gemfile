# encoding: utf-8
# frozen_string_literal: true

source 'https://rubygems.org'

ruby '2.4.1'

gem 'rails', '5.1.1'

gem 'pg'

gem 'sidekiq'
gem 'sidekiq-scheduler'
# for sidekiq web
gem 'sinatra', require: nil

gem 'json_translate'

gem 'haml'
gem 'haml-rails'
gem 'slim-rails'

gem 'secure_headers'

gem 'i18n-js', ">= 3.0.0.rc11"
gem 'js_cookie_rails'

gem 'devise'
gem 'omniauth'
gem 'omniauth-facebook'
gem 'omniauth-github'
gem 'omniauth-google-oauth2'
gem 'omniauth-twitter'

gem 'cancancan'

gem 'jbuilder'

gem 'dalli'
gem 'turbolinks'

gem 'kaminari'
gem 'select2-rails'
gem 'url_plumber'

gem 'dynamic_fields_for_rails'

gem 'state_machine'

gem 'bourbon'
gem 'coffee-rails'
gem 'sass-rails'

gem 'bootstrap-sass'
gem 'font-awesome-sass'

gem 'jquery-rails'
gem 'js-routes'

gem 'uglifier'

gem 'metadown'
gem 'redcarpet'

gem 'puma'

gem 'bower-rails'

gem 'highline'
gem 'thor'

gem 'carrierwave'
gem 'carrierwave-imageoptimizer'
gem 'mini_magick'

gem 'nokogiri', '>= 1.7.1'
gem 'typhoeus'

gem 'fog'

gem 'web_translate_it'

gem 'rack-cors', require: 'rack/cors'

gem 'sentry-raven'

gem 'lograge'

group :development do
  gem 'listen'
  gem 'pry-rails'
  gem 'rubocop', require: false
  gem 'spring'
  gem 'spring-watcher-listen'
  gem 'web-console'

  # deployment
  gem 'mina', require: false
  gem 'mina-multistage', require: false
end

group :test do
  gem 'codeclimate-test-reporter'
  gem 'database_cleaner'
  gem 'factory_girl'
  gem 'faker'
  gem 'minitest-rails'
  gem 'mocha', require: false
  gem 'rails-perftest'
  gem 'ruby-prof'
  gem 'simplecov', require: false
  gem 'simplecov-console', require: false
  gem 'simplecov-html', require: false
  gem 'timecop'
  gem 'vcr'
  gem 'webmock', require: false
end

group :development, :test do
  gem 'bullet'
  gem 'bundler-audit'
  gem 'byebug', platform: :mri
end
