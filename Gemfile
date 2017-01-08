source 'https://rubygems.org'

ruby '2.3.3'

gem "rails", "4.1.8"

gem 'pg'

gem 'sidekiq'
gem 'sidekiq-scheduler', '~> 2.0'
# for sidekiq web
gem "sinatra", ">= 1.3.0", require: nil

gem 'globalize'

gem 'haml'
gem 'haml-rails'
gem 'slim-rails'

gem "i18n-js", git: "https://github.com/fnando/i18n-js.git", branch: :master
gem "js_cookie_rails"

gem 'devise'
gem 'omniauth'
gem 'omniauth-github'
gem 'omniauth-twitter'
gem 'omniauth-facebook'
gem 'omniauth-google-oauth2'

gem 'cancan'

gem 'dalli'
gem 'actionpack-action_caching'
gem 'cache_digests'
gem 'turbolinks'

gem 'url_plumber'
gem 'select2-rails'
gem 'kaminari'

gem 'dynamic_fields_for_rails'

gem 'state_machine'

gem 'sass-rails'
gem 'coffee-rails'
gem 'bourbon'

gem 'bootstrap-sass'
gem 'font-awesome-sass'

gem 'jquery-rails'

gem 'asset_pipeline_routes'

gem 'uglifier'

gem 'metadown'
gem 'redcarpet'

gem 'puma'

gem "bower-rails"

gem 'thor'
gem 'highline'

gem 'carrierwave'
gem 'mini_magick'

gem 'typhoeus'

gem "fog"

gem 'web_translate_it'

gem "rails_12factor", group: :production

gem 'newrelic_rpm'

gem "sentry-raven"

group :development do
  gem 'pry-rails'
  gem 'rubocop', require: false
  gem 'web-console'
  gem 'listen', '~> 3.0.5'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
  gem "letter_opener"
end

group :test do
  gem 'faker'
  gem 'coveralls', require: false
  gem 'simplecov', require: false
  gem 'simplecov-console', require: false
  gem 'simplecov-html', require: false
  gem 'rails-perftest'
  gem 'minitest-rails'
  gem 'ruby-prof'
  gem 'database_cleaner'
  gem 'factory_girl'
  gem 'mocha', require: false
  gem "webmock", require: false
  gem 'timecop'
  gem "codeclimate-test-reporter", require: false
end

group :development, :test do
  gem 'bullet'
  gem 'byebug', platform: :mri
end
