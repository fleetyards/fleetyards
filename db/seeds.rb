# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).

if ENV['TEST_SEEDS'].present?
  require 'rsi_models_loader'

  RsiModelsLoader.new(vat_percent: Rails.application.secrets[:rsi_vat_percent]).all

  model = Model.first
  16.times do |index|
    model.images << Image.new(name: Rails.root.join("db/seeds/images/models/stub-#{index}.jpg").open, enabled: true)
  end

  require 'rsi_location_loader'

  RsiLocationLoader.new.all

  test_user = User.find_or_initialize_by(username: 'TestUser')
  test_user.skip_confirmation!
  test_user.update!(
    password: 'TestPassword',
    password_confirmation: 'TestPassword',
    email: 'test@fleetyards.net'
  )
end

Dir[File.join(Rails.root, 'db', 'seeds', '**', '*.rb')].sort.each do |seed|
  load seed
end