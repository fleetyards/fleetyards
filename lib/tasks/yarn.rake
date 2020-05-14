# frozen_string_literal: true

# yarn_install.rake
Rake::Task['yarn:install'].clear

namespace :yarn do
  # rubocop:disable Rails/RakeEnvironment
  task :install do
    # Redefine as empty
  end
  # rubocop:enable Rails/RakeEnvironment
end
