# frozen_string_literal: true

set :stage, :staging
set :rails_env, 'staging'
set :appsignal_env, :staging
set :branch, 'main'

server 'fleetyards-stage.mortik.xyz', user: 'fleetyards', roles: %w[web app db migration]
