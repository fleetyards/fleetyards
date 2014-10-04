require 'highline/import'

class Db < Thor

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
end
