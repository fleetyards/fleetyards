FactoryBot.define do
  factory :image do
    file { Rack::Test::UploadedFile.new(Rails.root.join("test/fixtures/files/test.png"), "image/png") }
    gallery { create(:model) }
    enabled { true }
    global { true }
  end
end
