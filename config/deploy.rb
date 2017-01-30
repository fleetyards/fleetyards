set :shared_dirs, [
  'public/uploads',
  'tmp/pids',
  'tmp/sockets'
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

set :deploy_to, '/home/fleetyards'
set :domain, '10.0.0.9'
set :branch, 'master'
set :repository, 'https://github.com/mortik/fleetyards'

if ENV['on'] == 'live'
  set :domain, 'fleetyards.net'
  # set :branch, 'master'
end

task :environment do
  invoke :'rbenv:load'
end

desc "Deploys the current version to the server."
task deploy: :environment do
  deploy do
    invoke :'git:clone'
    command 'rbenv install -s'
    command 'gem update --system 2.6.10'
    command 'gem install bundler --silent'
    invoke :'deploy:link_shared_paths'
    invoke :'bundle:install'

    invoke :'rails:db_migrate'
    invoke :'rails:assets_precompile'
    invoke :'deploy:cleanup'

    on :launch do
      invoke :phased_restart
    end
  end
end

task load_schema: :environment do
  in_path fetch(:current_path).to_s do
    invoke :stop
    comment %(Loading Schema for database)
    command %(#{fetch(:rake)} db:schema:load)
    invoke :start
  end
end

task migrate: :environment do
  in_path fetch(:current_path).to_s do
    comment %(Migrating database)
    command %(#{fetch(:rake)} db:migrate)
  end
end

task :phased_restart do
  invoke :'rbenv:load'
  command 'bundle exec pumactl -P tmp/pids/puma.pid -S tmp/sockets/puma.state -F config/puma.rb phased-restart'
  command 'sudo supervisorctl restart fleetyards:fleetyards-worker'
end

task :restart do
  comment 'Restart Application'
  command 'sudo supervisorctl restart fleetyards:*'
end

task :stop do
  comment 'Stopping Application'
  command 'sudo supervisorctl stop fleetyards:*'
end

task :start do
  comment 'Starting Application'
  command 'sudo supervisorctl start fleetyards:*'
end
