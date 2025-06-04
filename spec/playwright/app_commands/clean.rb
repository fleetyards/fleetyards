if defined?(DatabaseCleaner)
  # cleaning the database using database_cleaner
  DatabaseCleaner.strategy = :truncation
  DatabaseCleaner.clean
else
  logger.warn "add database_cleaner or update cypress/app_commands/clean.rb"
end

CypressOnRails::SmartFactoryWrapper.reload

Rails.logger.info "APPCLEANED" # used by log_fail.rb
