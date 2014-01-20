require 'highline/import'

class Db < Thor

  desc "reset_ships", "Reset Ships"
  def reset_ships
    require "./config/environment"
    ActiveRecord::Base.connection.execute("TRUNCATE ships;")
    ActiveRecord::Base.connection.execute("ALTER SEQUENCE ships_id_seq RESTART WITH 1;")
    ActiveRecord::Base.connection.execute("TRUNCATE equipment;")
    ActiveRecord::Base.connection.execute("ALTER SEQUENCE equipment_id_seq RESTART WITH 1;")
    ActiveRecord::Base.connection.execute("TRUNCATE weapons;")
    ActiveRecord::Base.connection.execute("ALTER SEQUENCE weapons_id_seq RESTART WITH 1;")
    ActiveRecord::Base.connection.execute("TRUNCATE hardpoints;")
    ActiveRecord::Base.connection.execute("ALTER SEQUENCE hardpoints_id_seq RESTART WITH 1;")
    ActiveRecord::Base.connection.execute("TRUNCATE equipment_ships;")
  end
end
