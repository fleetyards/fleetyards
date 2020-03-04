# frozen_string_literal: true

source 'https://rubygems.org'

ruby '~> 2.6'

gem 'rails', '6.0.2.1'

gem 'pg', '~> 1.0'

gem 'sidekiq'
gem 'sidekiq-cron'

gem 'paper_trail'

gem 'haml'
gem 'haml-rails'
gem 'slim-rails'

gem 'searchkick'

gem 'discordrb-webhooks'

gem 'selectize-rails'

gem 'ahoy_matey'
gem 'groupdate'

gem 'i18n-js'
gem 'js_cookie_rails'

gem 'inky-rb', require: 'inky'
# Stylesheet inlining for email **
gem 'foundation_emails'
gem 'premailer-rails'

gem 'cancancan'
gem 'devise'
gem 'jwt'
gem 'useragent'

gem 'ransack'

gem 'jbuilder'

gem 'rails-i18n'

gem 'dalli'

gem 'kaminari'
gem 'url_plumber'

gem 'dynamic_fields_for_rails'

gem 'state_machine'

gem 'bourbon'
gem 'coffee-rails'
gem 'sass-rails'
gem 'webpacker', '>= 4.0.x'

gem 'bootstrap-sass'

gem 'jquery-rails'
gem 'js-routes'

gem 'uglifier'

gem 'metadown'
gem 'redcarpet'

gem 'puma'
gem 'rack-attack'

gem 'bower-rails'

gem 'highline'
gem 'thor'

gem 'carrierwave'
gem 'fog-aws'
gem 'image_processing', '~> 1.0'
gem 'mini_magick'

gem 'nokogiri', '>= 1.7.1'
gem 'typhoeus'

gem 'rack-cors', require: 'rack/cors'

gem 'sentry-raven'

gem 'lograge'

gem 'pry-rails'

gem 'bootsnap', '>= 1.1.0', require: false

# Audit Issues
gem 'excon', '>= 0.71.0'

group :development do
  gem 'i18n-tasks', '~> 0.9.18'
  gem 'listen'
  gem 'rails-erd'

  gem 'dotenv'

  gem 'rubocop', require: false
  gem 'rubocop-performance'
  gem 'rubocop-rails'

  gem 'spring'
  gem 'spring-watcher-listen'
  gem 'web-console'

  gem 'bcrypt_pbkdf', require: false
  gem 'capistrano', '~> 3.11', require: false
  gem 'capistrano-rails', '~> 1.4', require: false
  gem 'capistrano-rails-console', require: false
  gem 'capistrano-rbenv', '~> 2.1', require: false
  gem 'ed25519', require: false
end

group :test do
  gem 'faker'
  gem 'minitest-ci'
  gem 'minitest-rails'
  gem 'mocha', require: false
  gem 'rails-perftest'
  gem 'ruby-prof'
  gem 'shoulda'
  gem 'shoulda-matchers'
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
  gem 'pry-byebug'

  # deployment
  gem 'mina', require: false
  gem 'mina-multistage', require: false
end
