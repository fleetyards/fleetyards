# frozen_string_literal: true

require "test_helper"

class Imports::HangarImportTest < ActiveSupport::TestCase
  test "a file that repeats a key imports with the last value" do
    file = Rack::Test::UploadedFile.new(
      StringIO.new('[{"name": "100i", "name": "125a", "type": "ship"}]'),
      "application/json",
      original_filename: "hangar.json"
    )

    import = Imports::HangarImport.create!(user: create(:user), import: file)

    assert_equal [{name: "125a", type: "ship"}], import.import_data
  end
end
