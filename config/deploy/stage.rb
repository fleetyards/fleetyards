# frozen_string_literal: true

set :application, 'fleetyards-stage'
set :rails_env, 'staging'
set :deploy_to, '/home/fleetyards-stage'
set :branch, 'master'

server 'erebor.mortik.xyz', user: 'fleetyards-stage', roles: %w[web app db migration]
