# frozen_string_literal: true

namespace :test do
  desc "Run Tests with Coverage"
  task :coverage do
    system("RAILS_TEST_COVERAGE=1 rails test", exception: true)
  end
end
