# frozen_string_literal: true

source 'https://rubygems.org'

ruby File.read('.ruby-version').chomp

gem 'rails', '7.0.1'

gem 'pg', '~> 1.0'

gem 'sidekiq'
gem 'sidekiq-cron'
gem 'sidekiq-statistic', github: 'davydovanton/sidekiq-statistic', branch: 'v1.5.1'

gem 'paper_trail'

gem 'haml'
gem 'haml-rails'

gem 'bootstrap'
gem 'i18n-js'
gem 'importmap-rails'
gem 'js-routes'
gem 'sassc-rails'
gem 'selectize-rails'
gem 'sprockets-rails'
gem 'stimulus-rails'
gem 'turbo-rails'

gem 'graphql-client'

gem 'searchkick'

gem 'discordrb-webhooks'

gem 'ahoy_matey'
gem 'groupdate'
gem 'rollups'

gem 'foundation_emails'
gem 'inky-rb', require: 'inky'
gem 'premailer-rails'

gem 'cancancan'

gem 'attr_encrypted', github: 'PagerTree/attr_encrypted', branch: 'rails-7-0-support'
gem 'devise'
gem 'devise-two-factor', github: 'mortik/devise-two-factor'
gem 'rqrcode'

gem 'useragent'

gem 'redis-actionpack', github: 'redis-store/redis-actionpack'

gem 'ransack'

gem 'jbuilder'
gem 'oj'

gem 'rails-i18n', '~> 7.0.0'

gem 'dalli'

gem 'kaminari'
gem 'url_plumber'

gem 'dynamic_fields_for_rails'

gem 'state_machine'

gem 'webpacker', '~> 5.x'

gem 'uglifier'

gem 'metadown'
gem 'redcarpet'

gem 'puma'
gem 'rack-attack'

gem 'highline'
gem 'thor'

gem 'aasm'
gem 'after_commit_everywhere'

gem 'carrierwave'
gem 'fog-aws'
gem 'image_processing', '~> 1.0'
gem 'mini_magick'

gem 'nokogiri', '1.13.1'

gem 'typhoeus'

gem 'rack-cors', require: 'rack/cors'

gem 'sentry-raven'

gem 'lograge'

gem 'pry-rails'

gem 'bootsnap', '>= 1.1.0', require: false

# Audit Issues
gem 'excon', '>= 0.71.0'

gem 'appsignal'

gem 'pghero'
gem 'pg_query', '>= 0.9.0'

group :development do
  gem 'annotate', github: 'dabit/annotate_models', branch: 'rails-7'

  gem 'i18n-tasks', '~> 0.9.18'
  gem 'listen'
  gem 'rails-erd'

  gem 'dotenv'
  gem 'dotenv-rails', require: 'dotenv/rails-now'

  gem 'rubocop', require: false
  gem 'rubocop-ast', require: false
  gem 'rubocop-minitest', '0.11.1', require: false
  gem 'rubocop-performance', require: false
  gem 'rubocop-rails', require: false
  gem 'rubocop-rake', require: false

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
  gem 'uniform_notifier', '1.14.0'

  gem 'bundler-audit'

  gem 'byebug', platform: :mri
  gem 'pry-byebug'

  gem 'knapsack'
end
