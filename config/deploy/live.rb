# frozen_string_literal: true

set :rails_env, 'production'
set :deploy_to, '/home/fleetyards'
set :branch, -> { ENV['CIRCLE_TAG'] || 'master' }
set :branch_spec, ->(rev) { available_tags.include?(rev) }
set :branch_spec_type, 'a git tag'

server 'erebor.mortik.xyz', user: 'fleetyards', roles: %w[web app db migration]

def available_tags
  `git tag --list --sort=version:refname`.split("\n").select { |tag| tag.match(/^\d/) }
end
