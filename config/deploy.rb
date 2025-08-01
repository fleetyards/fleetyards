# frozen_string_literal: true

lock "~> 3.11"

set :application, "fleetyards"
set :deploy_to, "/home/fleetyards"
set :repo_url, "https://github.com/fleetyards/fleetyards.git"

set :keep_releases, 5
set :keep_assets, 5

set :conditionally_migrate, true

file_content = File.read(".tool-versions")
ruby_version = if /^ruby\s+(.*)$/ =~ file_content
  $1.split("#", 2).first.strip
else
  file_content.strip
end

set :rbenv_type, :user
set :rbenv_ruby, ruby_version
set :bundler_version, "2.7.1"
set :gem_version, "3.7.1"
set :bundle_check_before_install, false # FIX: created failed deploys because dependencies where missing.

set :initial_deploy, false

set :linked_dirs, [
  "public/compare",
  "public/assets",
  "public/vite",
  ".bundle",
  "log",
  "tmp/cache",
  "tmp/pids",
  "tmp/sockets",
  "db/seeds_fleetchart",
  "dumps"
]

set :linked_files, [
  ".rbenv-vars",
  "blocklist.json",
  "reserved_usernames.json"
]

before :"rbenv:validate", :"ruby:prepare"
before :"deploy:migrate", :"db:load_schema"
after :"deploy:published", :"bundler:clean"

namespace :deploy do
  after :finished, :restart

  desc "Restart"
  task :restart do
    invoke :"server:restart_app"
    invoke :"server:restart_worker"
    invoke :"server:broadcast_version"
  end

  desc "Reload"
  task :reload do
    invoke :"server:reload_app"
    invoke :"server:restart_worker"
    invoke :"server:broadcast_version"
  end

  desc "Cleanup expired assets"
  task cleanup_assets: [:set_rails_env] do
    next unless fetch(:keep_assets)
    on release_roles(fetch(:assets_roles)) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          execute :rake, "'assets:clean[#{fetch(:keep_assets)}, 5184000]'"
        end
      end
    end
  end
end

namespace :ruby do
  desc "Prepare Ruby"
  task :prepare do
    on roles(:all) do
      info "Install Latest Ruby Version"
      rbenv_path = "$HOME/.rbenv"
      execute("#{rbenv_path}/bin/rbenv install #{fetch(:rbenv_ruby)} -s")
      execute("#{rbenv_path}/bin/rbenv global #{fetch(:rbenv_ruby)}")
      info "Update Rubygems"
      execute("#{rbenv_path}/shims/gem update --system #{fetch(:gem_version)} --no-document")
      info "Update/Install Bundler"
      execute("#{rbenv_path}/shims/gem install bundler -v #{fetch(:bundler_version)} --conservative --silent --force")
    end
  end
end

namespace :server do
  desc "Reload App"
  task :reload_app do
    on roles(:all) do
      info "Reload App"
      execute(:sudo, :service, "#{fetch(:application)}-app", :reload)
      execute(:sudo, :systemctl, "is-active", "--quiet", "#{fetch(:application)}-app.service")
      info "App Reloaded"
    end
  end

  desc "Restart App"
  task :restart_app do
    on roles(:all) do
      info "Restart App"
      execute(:sudo, :service, "#{fetch(:application)}-app", :restart)
      execute(:sudo, :systemctl, "is-active", "--quiet", "#{fetch(:application)}-app.service")
      info "App Restarted"
    end
  end

  desc "Restart Worker"
  task :restart_worker do
    on roles(:all) do
      info "Restart Worker"
      execute(:sudo, :service, "#{fetch(:application)}-worker", :restart)
      execute(:sudo, :systemctl, "is-active", "--quiet", "#{fetch(:application)}-worker.service")
      info "Worker Restarted"
    end
  end

  desc "Stop App & Worker"
  task :stop do
    on roles(:all) do
      info "Stop App"
      execute(:sudo, :service, "#{fetch(:application)}-app", :stop)
      info "App Stopped"

      info "Stop Worker"
      execute(:sudo, :service, "#{fetch(:application)}-worker", :stop)
      info "Worker Stopped"
    end
  end

  desc "Start App & Worker"
  task :start do
    on roles(:all) do
      info "Start Worker"
      execute(:sudo, :service, "#{fetch(:application)}-worker", :start)
      execute(:sudo, :systemctl, "is-active", "--quiet", "#{fetch(:application)}-worker.service")
      info "Worker Stared"

      info "Start App"
      execute(:sudo, :service, "#{fetch(:application)}-app", :start)
      execute(:sudo, :systemctl, "is-active", "--quiet", "#{fetch(:application)}-app.service")
      info "App Started"
    end
  end

  desc "Broadcast version"
  task :broadcast_version do
    on roles(:app) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          info "Broadcast Version"
          execute(:bundle, :exec, :thor, "broadcast:version")
        end
      end
    end
  end
end

desc "Tail logs"
task :logs do
  on roles(:app) do
    execute "tail -f #{shared_path}/log/*.log"
  end
end

namespace :bundler do
  task :reinstall do
    on roles(:app) do
      within release_path do
        execute(:bundle, :install, "--redownload")
      end
    end
  end
end

namespace :search do
  task :index do
    on roles(:app) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          info "Reindexing..."
          execute(:bundle, :exec, :thor, "search:index")
          info "Reindexing finished"
        end
      end
    end
  end
end

namespace :trading_data do
  task :import do
    on roles(:app) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          info "Import of Trading Data started..."
          execute(:bundle, :exec, :thor, "trading_data:import")
          info "Import finished"
        end
      end
    end
  end
end

namespace :sidekiq do
  task :clear do
    within release_path do
      with rails_env: fetch(:rails_env) do
        info "Clearing Sidekiq Queues..."
        execute(:bundle, :exec, :thor, "sidekiq:clear")
        info "Sidekiq cleared"
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
            execute :rails, "db:schema:load"
          else
            info "Skipping Load Schema"
          end
        end
      end
    end
  end

  task :sync_to_local do
    invoke :"db:backup"
    invoke :"db:download"
    invoke :"db:local_import"
  end

  task :migration_status do
    on roles(:db) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          info "Migration Status"
          execute(:rails, "db:migrate:status")
        end
      end
    end
  end

  task :seed do
    on roles(:db) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          info "Seeding database"
          execute(:rails, "db:seed")
        end
      end
    end
  end

  task :seed_fleetchart do
    on roles(:db) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          info "Seeding fleetcharts"
          execute(:rails, "db:seed FLEETCHART_SEEDS=true SKIP_SEEDS=true")
        end
      end
    end
  end

  task :migrate do
    on roles(:db) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          info "Migrating database"
          execute(:rails, "db:migrate")
        end
      end
    end
  end

  task :backup do
    on roles(:db) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          info "Creating DB Backup..."
          execute(:bundle, :exec, :thor, "db:dump")
          info "DB Backup finished"
        end
      end
    end
  end

  task :download do
    run_locally do
      info "Downloading latest backup..."
      execute(:mkdir, "-p", "dumps")
      server = roles(:db).first
      execute(:scp, "#{server.user}@#{server.hostname}:#{fetch(:deploy_to)}/shared/dumps/latest.dump", "dumps/")
      info "Download finished"
    end
  end

  task :local_import do
    run_locally do
      execute("./scripts/restore-db-backup.sh")
    end
  end
end
