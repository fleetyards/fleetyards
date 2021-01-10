# frozen_string_literal: true

set :application, 'fleetyards-stage'
set :rails_env, 'staging'
set :deploy_to, '/home/fleetyards-stage'
set :branch, 'main'

server 'stage.fleetyards.net', user: 'fleetyards-stage', roles: %w[web app db migration]
