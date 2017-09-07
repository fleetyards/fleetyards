# encoding: utf-8
# frozen_string_literal: true

source 'https://rubygems.org'

ruby '2.4.1'

gem 'rails', '5.1.3'

gem 'pg'

gem 'redis-namespace'
gem 'sidekiq'
gem 'sidekiq-cron'
# for sidekiq web
gem 'sinatra', require: nil

gem 'haml'
gem 'haml-rails'
gem 'slim-rails'

gem 'i18n-js', ">= 3.0.0.rc11"
gem 'js_cookie_rails'

gem 'inky-rb', require: 'inky'
# Stylesheet inlining for email **
gem 'foundation_emails'
gem 'premailer-rails'

gem 'cancancan'
gem 'devise'
gem 'jwt'

gem 'ransack'

gem 'jbuilder'

gem 'rails-i18n', '~> 5.0.0' # For 5.0.x and 5.1.x

gem 'dalli'
gem 'turbolinks'

gem 'kaminari'
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
gem 'rack-throttle'

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

gem 'rack-mini-profiler'

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
