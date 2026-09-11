# frozen_string_literal: true

require "test_helper"
require "support/hangar_import_fixtures"

class HangarImportHangarXplorTest < ActiveSupport::TestCase
  include HangarImportFixtures

  setup do
    load_loader_fixtures
    @user = create(:user)
    @import_file = Rack::Test::UploadedFile.new(Rails.root.join("test/fixtures/imports/hangarXPLOR.json"))
    @import = ::Imports::HangarImport.create!(user_id: @user.id, import: @import_file)
  end

  test "imports all data from hangarXPLOR export" do
    result = ::HangarImporter.new(@import).run
    assert_equal({missing: [], imported: HangarImportFixtures::IMPORTED_SHIPS_HANGAR_XPLOR, success: true}, result)
  end

  # The file the import modal offers as a download. A sample that stops
  # importing is worse than none, so it is imported here rather than trusted.
  test "the published example file imports cleanly" do
    file = Rack::Test::UploadedFile.new(Rails.root.join("public/examples/hangar-xplor-example.json"))
    import = ::Imports::HangarImport.create!(user_id: @user.id, import: file)

    result = ::HangarImporter.new(import).run

    assert_empty result[:missing]
    assert_equal ["325a", "Avenger Titan", "Cutlass Black"], result[:imported]
    assert_predicate Vehicle.where(user_id: @user.id).purchased, :any?
  end
end
