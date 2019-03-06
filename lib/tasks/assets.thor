# frozen_string_literal: true

require 'highline/import'

class Assets < Thor
  include Thor::Actions

  desc 'compile', 'Compile webpacker/sprocket assets'
  def compile
    puts '=> Webpacker compile...'
    run %(bundle exec rails webpacker:compile)

    puts '=> Assets precompile...'
    run %(bundle exec rails assets:precompile)
  end
end
