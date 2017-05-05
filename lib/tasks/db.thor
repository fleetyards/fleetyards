require 'highline/import'

class Db < Thor
  include Thor::Actions

  desc "reset_ships", "Reset Ships"
  def reset_ships
    require "./config/environment"
    ActiveRecord::Base.connection.execute("TRUNCATE ships;")
    ActiveRecord::Base.connection.execute("TRUNCATE ship_roles;")
    ActiveRecord::Base.connection.execute("TRUNCATE manufacturers;")
    ActiveRecord::Base.connection.execute("TRUNCATE component_categories;")
    ActiveRecord::Base.connection.execute("TRUNCATE components;")
    ActiveRecord::Base.connection.execute("TRUNCATE hardpoints;")
  end

  desc "dump", "Create new Database dump"
  def dump
    require "yaml"

    config = YAML.safe_load(IO.read("config/database.yml"))
    database_url = config["production"]["url"]

    run %(pg_dump -Fc --no-acl --no-owner #{database_url} -f dumps/latest.dump)
  end
end
