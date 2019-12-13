# frozen_string_literal: true

lock '~> 3.11'

set :application, 'fleetyards'
set :repo_url, 'https://github.com/fleetyards/fleetyards.git'

set :keep_releases, 5
set :keep_assets, 5

set :conditionally_migrate, true

set :rbenv_type, :user
set :rbenv_ruby, File.read('.ruby-version').strip
set :bundler_version, '2.0.2'

set :initial_deploy, false

set :linked_dirs, [
  'public/compare',
  'public/packs',
  'public/uploads',
  'log',
  'tmp/cache',
  'tmp/pids',
  'tmp/sockets',
  'dumps'
]

set :linked_files, [
  'config/database.yml',
  '.rbenv-vars',
  'blacklist.json'
]

before :'rbenv:validate', :'ruby:prepare'
before :'deploy:migrate', :'db:load_schema'

namespace :deploy do
  after :finished, :restart

  desc 'Restart'
  task :restart do
    invoke :'server:restart_app'
    invoke :'server:restart_worker'
    invoke :'server:broadcast_version'
  end
end

namespace :ruby do
  desc 'Prepare Ruby'
  task :prepare do
    on roles(:all) do
      info 'Install Latest Ruby Version'
      rbenv_path = '$HOME/.rbenv'
      execute("#{rbenv_path}/bin/rbenv install #{fetch(:rbenv_ruby)} -s")
      execute("#{rbenv_path}/bin/rbenv global #{fetch(:rbenv_ruby)}")
      info 'Update Rubygems'
      execute("#{rbenv_path}/shims/gem update --system")
      info 'Update/Install Bundler'
      execute("#{rbenv_path}/shims/gem install bundler -v #{fetch(:bundler_version)} --conservative --silent --force")
    end
  end
end

namespace :server do
  desc 'Restart App'
  task :restart_app do
    on roles(:all) do
      info 'Restart App'
      execute(:sudo, :service, "#{fetch(:application)}-app", :restart)
      execute(:sudo, :systemctl, 'is-active', '--quiet', "#{fetch(:application)}-app.service")
      info 'App Restarted'
    end
  end

  desc 'Restart Worker'
  task :restart_worker do
    on roles(:all) do
      info 'Restart Worker'
      execute(:sudo, :service, "#{fetch(:application)}-worker", :restart)
      execute(:sudo, :systemctl, 'is-active', '--quiet', "#{fetch(:application)}-worker.service")
      info 'Worker Restarted'
    end
  end

  desc 'Broadcast version'
  task :broadcast_version do
    on roles(:app) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          info 'Broadcast Version'
          execute(:bundle, :exec, :thor, 'broadcast:version')
        end
      end
    end
  end
end

desc 'Tail logs'
task :logs do
  on roles(:app) do
    execute "tail -f #{shared_path}/log/*.log"
  end
end

namespace :uploads do
  task :recreate_images do
    on roles(:app) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          info 'Recreate Images'
          execute(:bundle, :exec, :thor, 'images:recreate')
        end
      end
    end
  end

  task :sync_to_local do
    invoke :'uploads:backup'
    invoke :'uploads:download'
    invoke :'uploads:local_import'
  end

  task :backup do
    on roles(:app) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          info 'Creating Uploads Backup...'
          execute(:tar, '-zcvf', 'dumps/uploads.tar.gz', "#{fetch(:deploy_to)}/shared/public/uploads")
          info 'Uploads Backup finished'
        end
      end
    end
  end

  task :download do
    run_locally do
      info 'Downloading latest Uploads backup...'
      execute(:mkdir, '-p', 'dumps')
      server = roles(:app).first
      execute(:scp, "#{server.user}@#{server.hostname}:#{fetch(:deploy_to)}/shared/dumps/uploads.tar.gz", 'dumps/')
      info 'Download finished'
    end
  end

  task :local_import do
    run_locally do
      execute(:mkdir, '-p', 'public/uploads')
      execute(:tar, '--strip-components=5', '-xvzf', 'dumps/uploads.tar.gz', '-C', 'public/uploads/', "#{fetch(:deploy_to)}/shared/public/uploads")
    end
  end
end

namespace :es do
  task :index do
    on roles(:app) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          info 'Reindexing Elasticsearch...'
          execute(:bundle, :exec, :thor, 'search:index')
          info 'Reindexing finished'
        end
      end
    end
  end
end

namespace :db do
  task :load_schema do
    on roles(:db) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          if fetch(:initial_deploy)
            execute :rake, 'db:schema:load'
          else
            info 'Skipping Load Schema'
          end
        end
      end
    end
  end

  task :sync_to_local do
    invoke :'db:backup'
    invoke :'db:download'
    invoke :'db:local_import'
  end

  task :migration_status do
    on roles(:db) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          info 'Migration Status'
          execute(:rake, 'db:migrate:status')
        end
      end
    end
  end

  task :seed do
    on roles(:db) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          info 'Seeding database'
          execute(:rake, 'db:seed')
        end
      end
    end
  end

  task :migrate do
    on roles(:db) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          info 'Migrating database'
          execute(:rake, 'db:migrate')
        end
      end
    end
  end

  task :backup do
    on roles(:db) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          info 'Creating DB Backup...'
          execute(:bundle, :exec, :thor, 'db:dump')
          info 'DB Backup finished'
        end
      end
    end
  end

  task :download do
    run_locally do
      info 'Downloading latest backup...'
      execute(:mkdir, '-p', 'dumps')
      server = roles(:db).first
      execute(:scp, "#{server.user}@#{server.hostname}:#{fetch(:deploy_to)}/shared/dumps/latest.dump", 'dumps/')
      info 'Download finished'
    end
  end

  task :local_import do
    run_locally do
      execute(:pg_restore, '--verbose', '--clean', '--no-acl', '--no-owner', '-h', 'localhost', '-d', 'fleetyards_dev', 'dumps/latest.dump')
    end
  end
end
