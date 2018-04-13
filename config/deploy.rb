# frozen_string_literal: true

set :shared_dirs, [
  'public/uploads',
  'tmp/pids',
  'tmp/sockets',
  'dumps'
]

set :shared_files, [
  'config/secrets.yml',
  'config/database.yml'
]

require 'mina/bundler'
require 'mina/rails'
require 'mina/git'
require 'mina/rbenv'

set :user, 'fleetyards'
set :forward_agent, true

set :domain, 'erelas.mortik.xyz'
set :deploy_to, '/home/fleetyards'
set :repository, 'git@gitlab.com:fleetyards/api.git'
set :rails_env, 'production'
set :branch, 'master'
set :version_scheme, :datetime

task :remote_environment do
  invoke :'rbenv:load'
end

desc "Deploys the current version to the server."
task :deploy do
  deploy do
    invoke :'git:clone'
    comment 'Install Latest Ruby Version'
    command %(rbenv install -s)
    comment 'Update Rubygems'
    command %(gem update --system)
    comment 'Update/Install Bundler'
    command %(gem install bundler --conservative --silent)
    invoke :'deploy:link_shared_paths'

    invoke :'bundle:install'
    comment 'bundle clean'
    command %(bundle clean)

    invoke :'rails:db_migrate'
    invoke :'rails:assets_precompile'
    invoke :'deploy:cleanup'

    on :launch do
      invoke :'server:restart'
    end
  end
end

task assets_precompile: :remote_environment do
  in_path fetch(:current_path).to_s do
    comment %(Precompile Assets)
    command %(#{fetch(:rake)} assets:precompile)
  end
end

task assets_precompile: :remote_environment do
  in_path fetch(:current_path).to_s do
    comment %(Precompile Assets)
    command %(#{fetch(:rake)} assets:precompile)
  end
  invoke :'server:restart'
end

task recreate_images: :remote_environment do
  in_path fetch(:current_path).to_s do
    comment %(Recreate Images)
    command %(bundle exec thor images:recreate)
  end
end

task console: :remote_environment do
  set :execution_mode, :exec
  in_path fetch(:current_path).to_s do
    command %(#{fetch(:rails)} console)
  end
end

namespace :server do
  task :restart do
    comment 'Restart Application'
    command %(sudo supervisorctl restart fleetyards:*)
  end

  task :stop do
    comment 'Stopping Application'
    command %(sudo supervisorctl stop fleetyards:*)
  end

  task :start do
    comment 'Starting Application'
    command %(sudo supervisorctl start fleetyards:*)
  end
end

namespace :db do
  task load_schema: :remote_environment do
    in_path fetch(:current_path).to_s do
      invoke :'server:stop'
      comment %(Loading Schema for database)
      command %(#{fetch(:rake)} db:schema:load)
      invoke :'server:start'
    end
  end

  task migrate: :remote_environment do
    in_path fetch(:current_path).to_s do
      comment %(Migrating database)
      command %(#{fetch(:rake)} db:migrate)
    end
  end

  task backup: :remote_environment do
    in_path fetch(:current_path).to_s do
      comment "Creating DB Backup..."
      command %(bundle exec thor db:dump)
      comment "DB Backup finished"
    end
  end

  task :local_import do
    system %(pg_restore --verbose --clean --no-acl --no-owner -h localhost -d fleetyards_dev dumps/latest.dump)
  end

  # pg_restore --verbose --clean --no-acl --no-owner -h 127.0.0.1 -U fleetyards -d fleetyards dumps/latest.dump

  task :download_backup do
    comment "Downloading latest backup..."
    system %(scp #{fetch(:user)}@#{fetch(:domain)}:#{fetch(:deploy_to)}/shared/dumps/latest.dump dumps/)
    comment "Download finished"
  end
end
