# frozen_string_literal: true

namespace :test do
  desc 'Run Tests with Coverage'
  # rubocop:disable Rails/RakeEnvironment
  task :coverage do
    system('RAILS_TEST_COVERAGE=1 rails test')
  end
  # rubocop:enable Rails/RakeEnvironment
end
