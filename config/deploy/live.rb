# frozen_string_literal: true

set :rails_env, 'production'
set :deploy_to, '/home/fleetyards'
set :branch, 'master'

server 'erelas.mortik.xyz', user: 'fleetyards', roles: %w[web app db migration]
