# encoding: utf-8
# frozen_string_literal: true
source 'https://rubygems.org'

ruby '2.3.3'

gem 'rails', '4.1.8'

gem 'pg'

gem 'sidekiq'
gem 'sidekiq-scheduler', '~> 2.0'
# for sidekiq web
gem 'sinatra', '>= 1.3.0', require: nil

gem 'globalize'

gem 'haml'
gem 'haml-rails'
gem 'slim-rails'

gem 'i18n-js', git: 'https://github.com/fnando/i18n-js.git', branch: :master
gem 'js_cookie_rails'

gem 'devise'
gem 'omniauth'
gem 'omniauth-facebook'
gem 'omniauth-github'
gem 'omniauth-google-oauth2'
gem 'omniauth-twitter'

gem 'cancan'

gem 'cache_digests'
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

gem 'asset_pipeline_routes'

gem 'uglifier'

gem 'metadown'
gem 'redcarpet'

gem 'puma'

gem 'bower-rails'

gem 'highline'
gem 'thor'

gem 'carrierwave'
gem 'mini_magick'

gem 'nokogiri'
gem 'typhoeus'

gem 'fog'

gem 'web_translate_it'

gem 'heroku_rails_deflate', group: :production
gem 'rack-cors', require: 'rack/cors'
gem 'rails_12factor', group: :production

gem 'newrelic_rpm'

gem 'sentry-raven'

gem 'lograge'

group :development do
  gem 'letter_opener'
  gem 'listen', '~> 3.0.5'
  gem 'pry-rails'
  gem 'rubocop', require: false
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
  gem 'web-console'
end

group :test do
  gem 'codeclimate-test-reporter', require: false
  gem 'coveralls', require: false
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
  gem 'webmock', require: false
end

group :development, :test do
  gem 'bullet'
  gem 'byebug', platform: :mri
end
