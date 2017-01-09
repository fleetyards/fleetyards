require "thor"

class Heroku < Thor
  include Thor::Actions

  desc "deploy", "Start Deployment"
  option :migrate, type: :boolean, default: false, aliases: :m
  def deploy
    create_backup

    p "Deploying..."
    run "git push git@heroku.com:#{app}.git live:master"

    if options[:migrate]
      run_migrate
      restart_app
    end

    p "Deployment finished"
  end

  desc "import_backup", "Import Dump into Local DB"
  def import_backup
    create_backup
    download_backup
    run "pg_restore --verbose --clean --no-acl --no-owner -h localhost -d fleetyards_dev latest.dump"
  end

  desc "c", "Start Rails Console"
  def c
    invoke :console
  end

  desc "console", "Start Rails Console"
  def console
    run "heroku run rails c --app #{app}"
  end

  desc "logs", "Show Logs"
  option :n, type: :numeric, default: 300
  def logs
    run "heroku logs -n #{options[:n]} -t --app #{app}"
  end

  desc "migrate", "Migrate Database"
  def migrate
    run_migrate
    restart_app
  end

  desc "restart", "Restart App"
  def restart
    restart_app
  end

  desc "backup", "Backup Database"
  def backup
    create_backup
  end

  desc "maintenance", "Enable/Disable Maintenance"
  def maintenance(state = 'on')
    toggle_maintenance(state)
  end

  no_commands do
    private def run_migrate
      p "Migrate DB"
      toggle_maintenance('on')
      run "heroku run rake db:migrate --app #{app}"
      toggle_maintenance('off')
    end

    private def toggle_maintenance(state)
      run "heroku maintenance:#{state} --app #{app}"
    end

    private def restart_app
      p "Restart #{app}"
      run "heroku restart --app #{app}"
    end

    private def create_backup
      p "Backup DB"
      run "heroku pg:backups capture DATABASE_URL --app #{app}"
    end

    private def download_backup
      p "Starting Download for App #{app}"
      run "curl -o latest.dump $(heroku pg:backups:url --app #{app})"
      p "Download for App #{app} finished"
    end

    private def app
      @app ||= "fleetyards"
    end
  end
end
