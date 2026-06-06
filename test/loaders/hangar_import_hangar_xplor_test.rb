# frozen_string_literal: true

require "test_helper"
require_relative "../support/hangar_import_fixtures"

class HangarImportHangarXplorTest < ActiveSupport::TestCase
  include HangarImportFixtures

  setup do
    load_loader_fixtures
    @user = create(:user)
    @import_file = Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/imports/hangarXPLOR.json"))
    @import = ::Imports::HangarImport.create!(user_id: @user.id, import: @import_file)
  end

  test "imports all data from hangarXPLOR export" do
    result = ::HangarImporter.new(@import).run
    assert_equal({missing: [], imported: HangarImportFixtures::IMPORTED_SHIPS_HANGAR_XPLOR, success: true}, result)
  end
end
