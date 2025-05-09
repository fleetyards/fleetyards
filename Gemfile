# frozen_string_literal: true

source "https://rubygems.org"

ruby File.read(".ruby-version").chomp

gem "rails", "7.1.3.2"

gem "pg", "~> 1.0"

gem "sidekiq", "< 8"
gem "sidekiq-cron"

gem "paper_trail"

gem "haml"
gem "haml-rails"
gem "slim-rails"

gem "data_migrate"

gem "opensearch-ruby"
gem "searchkick"

gem "discordrb-webhooks"

gem "selectize-rails"

gem "vite_rails"

gem "ahoy_matey"
gem "groupdate"
gem "rollups"

gem "accept_language"
gem "i18n"
gem "i18n-js", "< 4.0"
gem "rails-i18n", "~> 7.0"

gem "js_cookie_rails"

gem "inky-rb", require: "inky"
# Stylesheet inlining for email **
gem "foundation_emails"
gem "premailer-rails"

gem "griddler"
gem "griddler-postmark", github: "r38y/griddler-postmark"
gem "postmark-rails"

gem "cancancan"

gem "devise"
gem "devise-two-factor"
gem "rqrcode"

gem "useragent"

gem "redis-actionpack"
gem "redis-store"

gem "ransack"

gem "deep_merge", require: "deep_merge/rails_compat"
gem "jbuilder"
gem "oj"
gem "responders"
gem "rswag-api"

gem "dalli"

gem "kaminari"
gem "url_plumber"

gem "dynamic_fields_for_rails"

gem "bourbon"
gem "coffee-rails"
gem "sass-rails"
gem "sprockets-rails"

gem "jquery-rails"
gem "js-routes"

gem "uglifier"

gem "metadown"
gem "redcarpet"

gem "puma"
gem "rack-attack"

gem "bower-rails"

gem "highline"
gem "thor"

gem "aasm"
gem "after_commit_everywhere"

gem "carrierwave"
gem "fog-aws"
gem "image_processing", "~> 1.0"
gem "mini_magick"
gem "ssrf_filter"

gem "nokogiri"
gem "typhoeus"

gem "rack-cors", require: "rack/cors"

gem "sentry-rails"
gem "sentry-ruby"
gem "sentry-sidekiq"

gem "lograge"

gem "pry-rails"

gem "bootsnap", ">= 1.1.0", require: false

gem "appsignal"

gem "pghero"
gem "pg_query", ">= 0.9.0"

gem "git"
gem "rdoc"

gem "psych", "~> 5.1.0"

gem "progress_bar"

# feature flag
gem "flipper"
gem "flipper-ui"
gem "flipper-active_record"

# openapi
gem "rspec-rails", require: false
gem "rswag-specs", require: false

group :development do
  gem "annotate"

  gem "i18n-tasks", "~> 1.0.5"
  gem "listen"
  gem "rails-erd"

  gem "dotenv"
  gem "dotenv-rails", require: "dotenv/load"

  gem "standard"

  gem "spring"
  gem "spring-watcher-listen"
  gem "web-console"

  gem "bcrypt_pbkdf", require: false
  gem "capistrano", "~> 3.11", require: false
  gem "capistrano-rails", "~> 1.4", require: false
  gem "capistrano-rails-console", require: false
  gem "capistrano-rbenv", "~> 2.1", require: false
  gem "ed25519", require: false

  gem "letter_opener"
end

group :test do
  gem "faker"
  gem "minitest-ci"
  gem "minitest-rails"
  gem "mocha", require: false
  gem "rails-perftest"
  gem "shoulda"
  gem "shoulda-matchers"
  gem "simplecov", require: false
  gem "simplecov-console", require: false
  gem "simplecov-html", require: false
  gem "timecop"
  gem "vcr"
  gem "webmock", require: false
end

group :development, :test do
  gem "bullet"
  gem "uniform_notifier"

  gem "bundler-audit"

  gem "factory_bot_rails", "~> 6.4.2"

  gem "byebug", platform: :mri
  gem "pry-byebug"

  gem "knapsack"
end

gem "enum_attributes_validation", "~> 0.1.7"

gem "bskyrb", "~> 0.5.3"

gem "x", "~> 0.14.0"

gem "graphlient"
