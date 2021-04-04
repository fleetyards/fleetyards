# frozen_string_literal: true

require 'highline/import'

class Db < Thor
  include Thor::Actions

  desc 'reset_models', 'Reset Models'
  def reset_models
    require './config/environment'
    ActiveRecord::Base.connection.execute('TRUNCATE models;')
    ActiveRecord::Base.connection.execute('TRUNCATE manufacturers;')
    ActiveRecord::Base.connection.execute('TRUNCATE component_categories;')
    ActiveRecord::Base.connection.execute('TRUNCATE components;')
    ActiveRecord::Base.connection.execute('TRUNCATE hardpoints;')
  end

  desc 'dump', 'Create new Database dump'
  def dump
    require './config/environment'

    database_url = ENV['DATABASE_URL']

    run %(pg_dump -Fc --no-acl --no-owner #{database_url} -f dumps/latest.dump)
  end
end
